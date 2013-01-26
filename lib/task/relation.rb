module Task
  class Relation
    %w[
      SubtaskMissingError
      SupertaskMissingError
      AlreadyRemovedError
      RemovalDateEarlierThanAdditionDateError
      AddingToCompleteSupertaskError
      RemovingFromCompleteSupertaskError
    ].each { |error_name| const_set(error_name, Class.new(Error)) }

    def nodes
      @nodes ||= ::Graph::EdgeNodes.new self
    end

    include Persistable


    def other_task(task)
      nodes.other(task)
    end

    attr_reader :type, :addition_date, :removal_date
    def initialize(attrs={})
      self.id = attrs[:id]

      @type = attrs.fetch(:type).to_sym

      @addition_date = attrs[:on] || attrs[:addition_date] || Time.current

      @connected = false
      @subtask, @supertask = *attrs.values_at(:subtask, :supertask)
      @subtask or
        raise SubtaskMissingError.new   relation: self, attributes: attrs
      @supertask or
        raise SupertaskMissingError.new relation: self, attributes: attrs

      validate_addition_to_completed_task
      @removal_date = Time::FOREVER
      if attrs.has_key? :removal_date
        remove on: attrs[:removal_date]
      end
      self.nodes.connect(@subtask, @supertask)
      @connected = true
    end

    def remove(opts={})
      new_removal_date = opts.fetch :on, Time.current
      validate_removal_date new_removal_date
      @removal_date = new_removal_date
      validate_removal_from_completed_task
      return self
    end

    def validate_removal_date(new_removal_date)
      unless !removed?
        raise AlreadyRemovedError.new \
          relation: self,
          new_removal_date: new_removal_date
      end

      unless new_removal_date >= addition_date
        raise RemovalDateEarlierThanAdditionDateError.new \
          relation: self,
          new_removal_date: new_removal_date
      end
    end

    def validate_addition_to_completed_task
      if type == :composition && @addition_date > @supertask.completion_date
        raise AddingToCompleteSupertaskError.new relation: self
      end
    end

    def validate_removal_from_completed_task
      if type == :composition && @removal_date > @supertask.completion_date
        raise RemovingFromCompleteSupertaskError.new relation: self
      end
    end


    def supertask
      nodes.parent
    end

    def subtask
      nodes.child
    end

    def effective_interval
      TimeInterval.new addition_date, removal_date
    end

    def effective_in?(given_time_interval)
      effective_interval.overlaps_with? given_time_interval
    end

    def effective_on?(given_date)
      effective_interval.include? given_date
    end


    def removed?
      removal_date != Time::FOREVER
    end


    def destroy
      self.nodes.disconnect
      @connected = false
      self
    end


    def inspect
      id_str = id.nil? ? '' : ":#{id}"
      connection_state = @connected ? '   connected' : 'disconnected'

      "<#{self.class}:#{sprintf('%016x', object_id)}#{id_str} #{type}" \
      " of #{@supertask.inspect} - #{@subtask.inspect}" \
      " (#{connection_state})" \
      " effective in #{effective_interval.inspect}>"
    end

  end
end
