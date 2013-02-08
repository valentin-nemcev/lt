module Task
  class Core
    attr_reader :effective_date

    def initialize(attrs={})
      @creation_date = attrs[:on] || attrs[:creation_date] || Time.current
      @completion_date = attrs[:completion_date] || Time::FOREVER
    end

    attr_reader :creation_date, :completion_date

    def completed?
      completion_date < Time::FOREVER
    end

    def completion_date=(new_date)
      # raise 'Task completed'
      !completed? or raise Error, "Couldn't redefine task completion date"
      new_date >= creation_date or raise Error,
        "Task couldn't be completed before it was created"
      @completion_date = new_date
    end

    def effective_interval
      TimeInterval.new creation_date, completion_date
    end

    def effective_in?(given_time_interval)
      effective_interval.overlaps_with? given_time_interval
    end


    def id
      object_id
    end

    def destroy
    end

    def creation_event
      @creation_event ||= CreationEvent.new(self)
    end

    def completion_event
      @completion_event ||= CompletionEvent.new(self) if completed?
    end

    def events
      [creation_event]
    end

    def inspect
      id_str = id.nil? || id == object_id ? '' : ":#{id}"
      "<#{self.class}:#{sprintf('%016x', object_id)}#{id_str}>"
    end
  end
end
