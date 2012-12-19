module Task
  module Attributes
  class Revision
    def initialize(attrs = {})
      @updated_value = attrs.fetch :updated_value
      @update_date   = attrs.fetch :update_date
      @owner         = attrs[:owner]
    end

    attr_reader :owner, :update_date, :updated_value
    def attribute_name; end

    def owner=(new_owner)
      owner.nil? or fail AttributeRevisionError.new owner, new_owner
      @owner = new_owner
    end

    def == other
      self.updated_value == other.updated_value &&
        self.update_date == other.update_date &&
        self.owner == other.owner
    end

    def different_from?(other)
      self.attribute_name != other.attribute_name ||
        self.updated_value != other.updated_value
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
end
