module Task
  class Graph
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

    def update_computed_attributes(args = {})
      update_date = args.fetch :after
      tasks.each{ |t| t.computed_attributes_updated :after => update_date }
    end

    def compute_events_from(events)
      computed_events = events.flat_map do |event|
        case event
        when CreationEvent
          event.task.compute_attributes_after_creation
        when UpdateEvent
          rev = event.revision
          rev.task.compute_attributes_after_attribute_update(rev)
        when AdditionEvent, RemovalEvent
          rel = event.relation
          date = event.date
          super_revs = rel.supertask.
            compute_attributes_after_relation_update(rel, :sub, date)
          sub_revs = rel.subtask.
            compute_attributes_after_relation_update(rel, :super, date)
          super_revs + sub_revs
        else
          raise UnknownEventType.new event: event
        end
      end.compact.collect_concat(&:events)
    end

    def new_events(args = {})
      update_date = args.fetch :after
      interval = TimeInterval.beginning_on update_date
      task = args.fetch :for
      tasks, relations = task.with_connected_tasks_and_relations
      tasks.each{ |t| t.computed_attributes_updated :after => update_date }
      created_tasks = tasks.select{ |t| interval.include? t.creation_date }
      relations = relations.select do |r|
        interval.include?(r.addition_date) ||
          r.removal_date && interval.include?(r.removal_date)
      end
      attribute_revisions = tasks.collect_concat do |t|
        t.attribute_revisions in: interval
      end
      (tasks + relations + attribute_revisions).collect_concat(&:events)
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
