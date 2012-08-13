module Task
  class InvalidTaskError < StandardError;   end;

  class Core
    # TODO: Consitent names for exceptions
    # TODO: Task ID in exception
    # TODO: Different exception classes for different errors
    class TaskDateInvalid < InvalidTaskError; end;

    include PersistenceMethods

    attr_reader :effective_date

    def fields
      @fields
    end
    protected :fields

    def ==(other)
      fields.equal? other.try(:fields)
    end

    def initialize(attrs={})
      @fields = {}
      now = attrs.fetch(:clock, Time).current
      fields[:created_on] = attrs[:on] || attrs[:created_on] || now
      @effective_date = [created_on, now].max
      super
    end

    def created_on
      fields[:created_on]
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


    def blocked?
      not subtasks.all?(&:completed?)
    end


    def inspect
      "<#{self.class}:#{self.id.inspect} #{self.objective} as of #{self.effective_date}>"
    end

    def as_json(options=nil)
      fields.dup
    end
  end
end
