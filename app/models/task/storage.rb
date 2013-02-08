module Task
  class Storage
    %w[
      TaskNotFoundError
      UnknownEventTypeError
    ].each { |error_name| const_set(error_name, Class.new(Error)) }

    attr_reader :user, :graph, :effective_interval
    def initialize(opts = {})
      @user = opts.fetch :user
      @effective_interval = opts.fetch(:effective_in,
                                       TimeInterval.for_all_time)
      clear_graph
    end

    def store_events(events)
      task_base.transaction do
        events.each do |event|
          case event
          when CreationEvent, CompletionEvent
            task_record = task_base.save_task(event.task)
          when Attributes::RevisionUpdateEvent
            event.changed_revisions.map do |revision|
              task_attribute_base.save_revision(revision)
            end
          when RelationEvent
            relation = event.relation
            relation_base.save_relation(relation)
          else
            raise UnknownEventTypeError.new event: event
          end
        end
      end
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

    def clear_graph
      @graph = Task::Graph.new
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

    def recompute_attributes!
      task_base.destroy_computed_attribute_revisions
      clear_graph
      fetch_all
      new_events = graph.all_events.sort_by(&:date).chunk(&:date).
        flat_map do |date, events|
        graph.compute_events_from(events)
      end
      store_events(new_events)
    end

    protected

    def fetch_scope(task_scope)
      effective_tasks = task_scope.effective_in(effective_interval)
      tasks = effective_tasks.load_tasks
      relations = effective_tasks.relations(tasks.map(&:id))
        .effective_in(effective_interval)
        .load_relations(tasks.index_by(&:id))
      graph.add_tasks tasks: tasks, relations: relations
    end

    def task_base
      Task::Record.for_user user
    end

    def task_attribute_base
      Task::AttributeRevisionRecord
    end

    def relation_base
      Task::RelationRecord
    end

  end
end
