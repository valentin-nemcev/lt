module Task
  class Graph

    class IncompleteGraphError < StandardError
      def initialize(incomplete)
        @incomplete = incomplete
      end

      def message
        "Incomplete relations: " + @incomplete.map(&:inspect).join(', ')
      end
    end


    def self.new_from_records(records = {})
      allocate.tap{ |o| o.initialize_with_records(records) }
    end

    def initialize_with_records(opts = {})
      relations = opts.fetch(:relations, [])

      incomplete = relations.select(&:incomplete?)
      fail IncompleteGraphError, incomplete if incomplete.present?

      @tasks_and_relations = [opts.fetch(:tasks, []), relations]
    end


    def initialize(opts = {})
      @given_tasks = opts.fetch :tasks, []
    end

    def tasks
      tasks_and_relations[0]
    end

    def revisions
      tasks.collect_concat(&:attribute_revisions)
    end

    def computed_revisions *args
      tasks.collect_concat{ |t| t.computed_attribute_revisions *args }
    end

    def find_task_by_id(id)
      tasks.find{ |task| task.id.to_s == id.to_s }
    end

    def relations
      tasks_and_relations[1]
    end

    def tasks_and_relations
      @tasks_and_relations ||= build_tasks_and_relations
    end

    protected
    def build_tasks_and_relations
      task_set, relation_set = Set.new, Set.new
      @given_tasks.each do |task|
        next if task_set.include? task
        tasks, relations = task.with_connected_tasks_and_relations
        task_set.merge tasks
        relation_set.merge relations
      end
      [task_set, relation_set]
    end

  end
end
