module Task
  class CompletionEvent < Event
    alias_method :task, :target

    def type
      'task_completion'
    end

    def id
      task.id
    end

    def date
      task.completion_date
    end

    def as_json(*)
      super.merge :task_id => task.id
    end
  end
end
