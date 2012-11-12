module Task
  class AttributeRevision
    def initialize(opts={})
      @updated_value   = opts.fetch :updated_value
      @updated_on      = opts.fetch :updated_on
      @owner = opts[:owner]
    end

    attr_reader :owner, :updated_on, :updated_value
    def attribute_name; end

    def owner=(new_owner)
      owner.nil? or fail AttributeRevisionError.new owner, new_owner
      @owner = new_owner
    end

    def == other
      self.updated_value == other.updated_value &&
        self.updated_on == other.updated_on &&
        self.owner == other.owner
    end

    alias_method :task, :owner

    def task_id
      task.id
    end
  end

  class AttributeRevisionError < StandardError
    def initialize(last, current)
      @last, @current = last, current
    end

    def message
      "Can't change revision owner"\
        " last: #{@last}, current: #{@current}"
    end
  end

end
