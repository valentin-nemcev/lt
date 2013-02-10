module Task
  class CreationEvent < Event
    alias_method :task, :target

    def type
      'task_creation'
    end

    def id
      task.id
    end

    def date
      task.creation_date
    end

    def attribute_changes
      task.computed_attributes_after_creation
    end

    def as_json(*)
      super.merge :task_id => task.id
    end
  end
end
