require 'time_infinity'
require 'singleton'

class TimeInterval

  def self.for_all_time
    new Time::NEVER, Time::FOREVER
  end

  def self.beginning_on(beginning)
    new beginning, Time::FOREVER
  end

  def self.ending_on(ending)
    new Time::NEVER, ending
  end

  def self.empty
    Empty.instance
  end

  def self.new(beginning, ending)
    ending <= beginning ? empty : super
  end

  attr_reader :beginning, :ending
  def initialize(beginning, ending)
    @beginning, @ending = beginning, ending
  end

  def == other
    self.beginning == other.beginning && self.ending == other.ending
  end

  def include?(given_date)
    beginning <= given_date && given_date < ending
  end
  alias_method :includes?, :include?

  def include_with_end?(given_date)
    beginning <= given_date && given_date <= ending
  end
  alias_method :includes_with_end?, :include_with_end?

  def & other
    return other if other.empty?
    self.class.new \
      [self.beginning, other.beginning].max,
      [self.ending, other.ending].min
  end

  def overlaps_with?(other)
    not (self & other).empty?
  end

  def empty?
    false
  end

  class Empty
    include Singleton

    def beginning
      raise NoMethodError, 'Empty interval has no beginning'
    end

    def ending
      raise NoMethodError, 'Empty interval has no ending'
    end

    def include?(_)
      false
    end
    alias_method :includes?, :include?

    def include_with_end?(_)
      false
    end
    alias_method :includes_with_end?, :include_with_end?

    def & other
      self
    end

    def overlaps_with?(_)
      false
    end

    def empty?
      true
    end
  end
end
