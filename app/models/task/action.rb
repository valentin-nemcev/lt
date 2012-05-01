class Task::Action < Task::Task
  attr_reader :completed_on

  def actionable?
    !completed? && !blocked?
  end

  def completed?
    completed_on && effective_date >= completed_on
  end


  def complete!(opts={})
    completed_on = opts.fetch :on, effective_date
    if completed_on < self.created_on
      raise TaskDateInvalid, "Task couldn't be completed before it was created"
    end
    @completed_on = completed_on
    return self
  end

  def undo_complete!
    @completed_on = nil
    return self
  end
end
