module Task
  class Attributes::Revision
    def initialize(attrs = {})
      @owner           = attrs[:owner]
      @update_date     = attrs.fetch :update_date
      @updated_value   = attrs.fetch :updated_value
      @sequence_number = attrs[:sequence_number]
    end

    attr_reader :owner, :update_date, :updated_value, :sequence_number
    def attribute_name; end
    def computed?; false; end

    def owner=(new_owner)
      owner.nil? or fail OwnerError.new owner, new_owner
      @owner = new_owner
    end

    def == other
      self.updated_value == other.updated_value &&
        self.update_date == other.update_date &&
        self.attribute_name == other.attribute_name &&
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

    class OwnerError < Task::Error
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