module Task
  class LegacyMapper

    def initialize
      @task_scope = LegacyRecord.scoped
    end

    def records
      @task_scope.all
    end

    def for_user(user)
      @task_scope = @task_scope.where(user_id: user.id)
      self
    end

    def fetch_all(opts={})
      tasks = {}
      records.each do |record|
        task = map_record_to_task record
        tasks[record.id] = task
        task.id = nil if opts[:dont_persist]

        unless record.root?
          parent_task = tasks[record.parent.id]
          Relation.new(
            subtask: task,
            supertask: parent_task,
            type: :composition,
            added_on: [task, parent_task].map(&:created_on).max
          )
        end
      end
      return tasks.values
    end

    def map_record_to_task record
      fields = {
        id: record.id,
        created_on: record.created_on,
        objective: record.body,
        state: 'underway'
      }
      cls = record.leaf? ? Action : Project
      cls.new(fields).tap do |task|
        if record.completed_on && record.leaf?
          task.update_state 'completed', on: record.completed_on
        end
      end
    end

  end
end
