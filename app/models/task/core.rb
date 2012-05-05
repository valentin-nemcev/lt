module Task
  class InvalidTaskError < StandardError;   end;

  class Core
    class TaskDateInvalid < InvalidTaskError; end;

    attr_reader :effective_date, :created_on

    def initialize(attrs={})
      now = Time.current
      @created_on = attrs.fetch(:on, now)
      @effective_date = [@created_on, now].max
    end

    def initialize_copy(original)
      @original = original
      super
    end

    def original
      @original or self
    end
    protected :original

    def ==(other)
      original.equal? other.original
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
      "<#{self.class}: #{self.objective} as of #{self.effective_date}>"
    end
  end
end
