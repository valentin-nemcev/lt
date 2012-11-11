module Task
  class AttributeRevision
    def initialize(opts={})
      @updated_value   = opts.fetch :updated_value
      @updated_on      = opts.fetch :updated_on
      @sequence_number = opts.fetch :sequence_number
      @owner = opts[:owner]
    end

    attr_reader :owner, :updated_on, :updated_value, :sequence_number
    def attribute_name; end

    def owner=(new_owner)
      owner.nil? or fail AttributeRevisionError.new owner, new_owner
      @owner = new_owner
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
