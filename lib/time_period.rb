class TimePeriod < Interval

  def self.for_all_time
    new nil, nil
  end

  def self.from(beginning)
    new beginning, nil
  end

  def self.to(ending)
    new nil, ending
  end

  def initialize(beginning, ending)
    super left_closed: beginning, right_open: ending
  end

  alias_method :beginning, :left_endpoint
  alias_method :ending,    :right_endpoint
end
