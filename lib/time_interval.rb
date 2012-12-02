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

  def & other
    self.class.new \
      [self.beginning, other.beginning].max, [self.ending, other.ending].min
  end

  alias_method :beginning, :left_endpoint
  alias_method :ending,    :right_endpoint
end
