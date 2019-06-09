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
      ap events
      merge_attribute_changes(events.sort.collect_concat(&:attribute_changes)).
        collect(&:attribute_revision).compact.collect(&:update_event)
    end

    def merge_attribute_changes(changes)
      puts "changes: #{changes.length}"
      exit if changes.length > 100
      merged = Hash.new { |h, k| h[k] = [] }
      changes.reverse.each_with_object(merged) do |change, merged|
        merged[change.merge_attrs].push(change)
      end.map do |_, changes|
        changes.reverse.reduce(&:merge)
      end.reverse
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
