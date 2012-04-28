class Action < Task
  attr_reader :completed_on

  def actionable?
    !completed? && !blocked?
  end

  def completed?
    completed_on && effective_date >= completed_on
  end


  def complete!(opts={})
    date = opts[:on]
    if date && date < self.created_on
      raise TaskDateInvalid, "Task couldn't be completed before it was created"
    end
    @completed_on = bump_effective_date date
    return self
  end

  def undo_complete!
    @completed_on = nil
    return self
  end
end
