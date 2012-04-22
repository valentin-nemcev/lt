class TaskDateInvalid < StandardError; end;
class Task

  attr_reader :effective_date, :created_on

  def initialize(attrs={})
    now = Time.current
    @created_on = attrs.fetch(:on, now)
    @effective_date = [@created_on, now].max

    @supertasks = []
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


  protected

  def bump_effective_date date
    date || self.effective_date = Time.current
  end
end
