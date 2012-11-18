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

      @tasks = Set.new(opts.fetch(:tasks, []))
      @relations = Set.new(relations)
    end


    def new_task(*args)
      task = Task.new_subtype *args
      add_tasks [task]
      task
    end


    def initialize(opts = {})
      add_tasks opts.fetch :tasks, []
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


    def events(args = {})
      interval = args.fetch :in
      if task = args[:for]
        tasks, relations = task.with_connected_tasks_and_relations
      else
        tasks, relations = self.tasks, self.relations
      end
      created_tasks = tasks.select{ |t| interval.include? t.created_on }
      relations = relations.select{ |r| interval.include? r.added_on }
      attribute_revisions = tasks.collect_concat do |t|
        t.attribute_revisions in: interval
      end
      [created_tasks, relations, attribute_revisions]
    end

    protected
    def add_tasks given_tasks
      given_tasks.each do |task|
        next if tasks.include? task
        new_tasks, new_relations = task.with_connected_tasks_and_relations
        tasks.merge new_tasks
        relations.merge new_relations
      end
    end

  end
end
