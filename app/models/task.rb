class TaskDateInvalid < StandardError; end;
class Task

  attr_reader :effective_date, :created_on, :completed_on

  def initialize(attrs={})
    now = Time.current
    @created_on = attrs.fetch(:on, now)
    @effective_date = [@created_on, now].max
  end


  def as_of(date)
    clone.tap { |t| t.effective_date = date }
  rescue TaskDateInvalid
    nil
  end

  def effective_date=(date)
    if date < self.created_on
      raise TaskDateInvalid, "Task didn't exist as of #{date}"
    end
    @effective_date = date
    return self
  end


  def actionable?
    !completed?
  end

  def completed?
    completed_on && effective_date >= completed_on
  end

  def blocked?
    false
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

  protected

  def bump_effective_date date
    date || self.effective_date = Time.current
  end
end
