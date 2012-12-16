module Task
  class Storage
    class TaskNotFoundError < StandardError; end

    attr_reader :user, :graph
    def initialize(opts = {})
      @user = opts.fetch :user
      @graph = Task::Graph.new
    end

    def store(task)
      graph.add_tasks_with_connected [task]
      store_graph
    end

    def store_graph
      task_records = graph.tasks.map do |task|
        task_base.save_task(task)
      end

      task_records_map = task_records.index_by(&:id)
      relation_records = graph.relations.map do |relation|
        relation_base.save_relation(relation, task_records_map)
      end
      graph
    end

    def fetch(task_id)
      task = graph.find_task_by_id(task_id)
      fetch_scope(task_base.graph_scope(task_id)) if !task
      task = graph.find_task_by_id(task_id)
      fail TaskNotFoundError if !task
      task
    end

    def fetch_all
      fetch_scope(task_base.all_graph_scope).tasks
      graph
    end

    def destroy_task(task)
      task_base.destroy_task(task)
      task.destroy{ |related_task| destroy_task related_task }
      task.freeze
      nil
    end

    protected

    def fetch_scope(task_scope)
      tasks = task_scope.load_tasks
      relations = task_scope.relations.load_relations(tasks.index_by(&:id))
      graph.add_tasks tasks: tasks, relations: relations
    end

    def task_base
      Task::Records::Task.for_user user
    end

    def relation_base
      Task::Records::TaskRelation
    end

  end
end
