module Task
  class Storage
    class TaskNotFoundError < StandardError
    end

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
        task_base.save_task(task).tap { |rec| task.id = rec.id }
      end

      relation_records = graph.relations.map do |relation|
        relation_base.save_relation(relation, task_records.index_by(&:id))
          .tap { |rec| relation.id = rec.id }
      end
      graph
    end

    def fetch(task_id)
      fetch_scope(task_base.graph_scope(task_id)).tasks.find do |task|
        task.id == task_id
      end
    end

    def fetch_all
      fetch_scope(task_base.all_graph_scope).tasks
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
      Task::Records::Relation
    end

  end
end
