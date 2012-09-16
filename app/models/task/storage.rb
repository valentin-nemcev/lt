module Task
  class Storage
    class TaskNotFoundError < StandardError; end
    class IncompleteGraphError < StandardError; end

    attr_reader :user
    def initialize(opts = {})
      @user = opts.fetch :user
    end

    def store(task)
      graph = Task::Graph.new tasks: [task]
      store_graph graph
    end

    def store_graph(graph)
      task_records = graph.tasks.map do |task|
        fail IncompleteGraphError if task.nil?
        task_base.save_task(task)
      end

      task_records_map = task_records.index_by(&:id)
      relation_records = graph.relations.map do |relation|
        relation_base.save_relation(relation, task_records_map)
      end
      graph
    end

    def fetch(task_id)
      graph = fetch_scope(task_base.graph_scope(task_id))
      graph.find_task_by_id(task_id) or fail TaskNotFoundError
    end

    def fetch_graph
      fetch_scope(task_base.all_graph_scope)
    end

    def fetch_all
      fetch_scope(task_base.all_graph_scope).tasks
    end

    def destroy_task(task)
      task_base.destroy_task(task)
      task.destroy_relations
      task.freeze
      nil
    end

    protected

    def fetch_scope(task_scope)
      tasks = task_scope.load_tasks
      relations = task_scope.relations.load_relations(tasks.index_by(&:id))
      Task::Graph.new_from_records tasks: tasks, relations: relations
    end

    def task_base
      Task::Records::Task.for_user user
    end

    def relation_base
      Task::Records::TaskRelation
    end

  end
end
