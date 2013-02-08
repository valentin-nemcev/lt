module Task
  class Event
    def initialize(target)
      @target = target
    end
    attr_reader :target

    def type
    end

    def id
    end

    def date
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
