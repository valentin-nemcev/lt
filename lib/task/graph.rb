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
      task
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


    def events(args = {})
      interval = args.fetch :in
      if task = args[:for]
        tasks, relations = task.with_connected_tasks_and_relations
      else
        tasks, relations = self.tasks, self.relations
      end
      created_tasks = tasks.select{ |t| interval.include? t.creation_date }
      relations = relations.select do |r|
        interval.include?(r.addition_date) ||
          r.removal_date && interval.include?(r.removal_date)
      end
      attribute_revisions = tasks.collect_concat do |t|
        t.attribute_revisions in: interval
      end
      [created_tasks, relations, attribute_revisions]
    end

  end
end
