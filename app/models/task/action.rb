module Task
  class Action < Base

    def initialize(attrs={})
      super

      self.completed_on = attrs[:completed_on]
    end

    def completed_on
      fields[:completed_on]
    end

    def completed_on=(completed_on)
      if completed_on && completed_on < self.created_on
        raise TaskDateInvalid, "Task couldn't be completed before it was created"
      end
      fields[:completed_on] = completed_on
    end

    def actionable?
      !completed? && !blocked?
    end

    def completed?
      completed_on && effective_date >= completed_on
    end


    def complete!(opts={})
      self.completed_on = opts.fetch :on, effective_date
      return self
    end

    def undo_complete!
      self.completed_on = nil
      return self
    end

  end
end
