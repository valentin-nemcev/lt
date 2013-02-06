module Task
  class Graph
    %w[
      UnknownEventTypeError
    ].each { |error_name| const_set(error_name, Class.new(Error)) }
    def add_tasks(args = {})
      given_relations = args.fetch(:relations, [])

      given_tasks = args.fetch(:tasks, [])

      tasks.merge(given_tasks)
      relations.merge(given_relations)
      self
    end

    def add_tasks_with_connected given_tasks
      given_tasks.each do |task|
        new_tasks, new_relations = task.with_connected_tasks_and_relations
        tasks.merge new_tasks
        relations.merge new_relations
      end
      self
    end


    def new_task(*args)
      task = Task::Base.new *args
      add_tasks_with_connected [task]
      [[task.creation_event, *task.editable_attribute_events], task]
    end


    def initialize(opts = {})
      add_tasks_with_connected opts.fetch(:tasks, [])
    end

    def relations
      @relations ||= Set.new
    end

    def tasks
      @tasks ||= Set.new
    end

    def attribute_revisions
      tasks.collect_concat(&:attribute_revisions)
    end

    def computed_revisions *args
      tasks.collect_concat{ |t| t.computed_attribute_revisions *args }
    end

    def find_task_by_id(id)
      tasks.find{ |task| task.id.to_s == id.to_s }
    end

    def compute_events_from(events)
      attrs_to_compute = events.flat_map do |event|
        case event
        when CreationEvent
          event.task.computed_attributes_after_creation
        when CompletionEvent
        when UpdateEvent
          rev = event.revision
          rev.task.computed_attributes_after_attribute_update(rev)
        when AdditionEvent, RemovalEvent
          rel = event.relation
          date = event.date
          super_revs = rel.supertask.
            computed_attributes_after_relation_update(rel.type, :sub, date)
          sub_revs = rel.subtask.
            computed_attributes_after_relation_update(rel.type, :super, date)
          super_revs + sub_revs
        else
          raise UnknownEventTypeError.new event: event
        end
      end.compact
      attrs_to_compute.reverse.uniq.reverse.
        map do |task, attr, date|
        task.compute_attribute(attr, date)
      end.compact.collect(&:update_event)
    end

    def all_events
      tasks, relations = self.tasks, self.relations
      attribute_revisions = tasks.collect_concat do |t|
        t.attribute_revisions in: TimeInterval.for_all_time
      end
      (tasks + relations + attribute_revisions).collect_concat(&:events)
    end
  end
end
