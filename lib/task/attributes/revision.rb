module Task
  class Attributes::Revision
    %w[
      NextDateAlreadySetError
      NextDateEarlierThanUpdateDateError
      OwnerAlreadySetError
    ].each { |error_name| const_set(error_name, Class.new(Error)) }

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
    def next_update_date=(new_next_update_date)
      if has_next?
        raise NextDateAlreadySetError.new \
          revision: self,
          new_next_update_date: new_next_update_date
      end

      if new_next_update_date < update_date
        raise NextDateEarlierThanUpdateDateError.new \
          revision: self,
          new_next_update_date: new_next_update_date
      end
      @next_update_date = new_next_update_date
    end

    def has_next?
      next_update_date != Time::FOREVER
    end

    attr_reader :owner
    def owner=(new_owner)
      if owner.present?
        raise OwnerAlreadySetError.new \
          revision: self,
          new_owner: new_owner
      end
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

    def events
      [{
        :type           => 'task_update',
        :id             => "#{self.id}-#{self.task_id}",
        :task_id        => self.task_id,
        :attribute_name => self.attribute_name,
        :updated_value  => self.updated_value,
        :date           => self.update_date.httpdate,
      }]
    end

    def task_id
      task.id
    end
  end
end
