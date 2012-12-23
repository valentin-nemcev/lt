require 'singleton'

class Time
  class Infinity
    include Singleton

    def == other
      self.class == other.class
    end

    include Comparable

    def <=> other
      self == other ? 0 : value <=> 0.0
    end

    def to_datetime
      value
    end

    def to_time
      value
    end

    def inspect
      "#<#{self.class.name}>"
    end
  end

  class Forever < Time::Infinity
    def value
      Float::INFINITY
    end
  end

  class Never < Time::Infinity
    def value
      -(Float::INFINITY)
    end
  end

  FOREVER = Forever.instance
  NEVER   = Never.instance
end
