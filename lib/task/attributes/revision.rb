module Task
  class Attributes::Revision
    def initialize(attrs = {})
      @update_date     = attrs.fetch :update_date
      @updated_value   = attrs.fetch :updated_value
      @sequence_number = attrs[:sequence_number]

      self.owner = attrs[:owner]

      @next_update_date = Time::FOREVER
      attrs[:next_update_date].try { |date| self.next_update_date = date }
    end

    attr_reader :update_date, :updated_value, :sequence_number
    def attribute_name; end
    def computed?; false; end

    attr_reader :next_update_date
    def next_update_date=(new_date)
      new_date.present? or raise ArgumenError
      !has_next? or
        raise RevisionNextDateOverrideError.new next_update_date, new_date

      new_date >= update_date or
        raise InvalidRevisionNextDateError.new update_date, new_date
      @next_update_date = new_date
    end

    def has_next?
      next_update_date != Time::FOREVER
    end

    attr_reader :owner
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

    class RevisionNextDateOverrideError < Task::Error
      def initialize(last, current)
        @last, @current = last, current
      end

      def message
        "Couldn't redefine relation removal date:"\
          " last: #{@last}, current: #{@current}"
      end
    end

    class InvalidRevisionNextDateError < Task::Error
      def initialize(update_date, next_update_date)
        @update_date, @next_update_date = update_date, next_update_date
      end

      def message
        "Invalid revision next update date:"\
          " update date: #{@update_date}, next update date: #{@next_update_date}"
      end
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
