require 'time_infinity'

class TimeInterval < Interval

  def self.for_all_time
    new Time::NEVER, Time::FOREVER
  end

  def self.beginning_at(beginning)
    new beginning, Time::FOREVER
  end

  def self.ending_at(ending)
    new Time::NEVER, ending
  end

  def include_with_end?(given_date)
    self.beginning <= given_date && self.ending <= given_date
  end

  def initialize(beginning, ending = nil)
    if beginning.is_a? Hash
      super beginning
    else
      super left_closed: beginning, right_open: ending
    end
  end

  def == other
    self.beginning == other.beginning && self.ending == other.ending
  end

  # TODO: Remove compact (don't use nil as time infinity)
  def & other
    self.class.new \
      [self.beginning, other.beginning].compact.max,
      [self.ending, other.ending].compact.min
  end

  alias_method :beginning, :left_endpoint
  alias_method :ending,    :right_endpoint
end
