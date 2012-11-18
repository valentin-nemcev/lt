class TimeInterval < Interval

  def self.for_all_time
    new nil, nil
  end

  def self.beginning_at(beginning)
    new beginning, nil
  end

  def self.ending_at(ending)
    new nil, ending
  end

  def initialize(beginning, ending)
    super left_closed: beginning, right_open: ending
  end

  alias_method :beginning, :left_endpoint
  alias_method :ending,    :right_endpoint
end
