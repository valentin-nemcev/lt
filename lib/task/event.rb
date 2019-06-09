module Task
  class Event
    def initialize(target)
      @target = target
    end
    attr_reader :target

    def priority
      0
    end

    include Comparable
    def <=> other
      self.priority <=> other.priority
    end

    def type
    end

    def id
    end

    def date
    end

    def attribute_changes
      []
    end

    def as_json(*)
      {
        :id   => id,
        :type => type,
        :date => date.httpdate,
      }
    end
  end
end
