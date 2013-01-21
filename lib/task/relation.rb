module Task
  class InvalidRelationError < Task::Error; end;
  class Relation

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
      now = attrs.fetch(:clock, Time).current
      @addition_date = attrs[:on] || attrs[:addition_date] || now
      subtask, supertask = attrs.fetch(:subtask), attrs.fetch(:supertask)
      subtask or raise InvalidRelationError, 'Subtask missing'
      supertask or raise InvalidRelationError, 'Supertask missing'
      validate_addition_to_completed_task(addition_date, supertask)
      @removal_date = Time::FOREVER
      if attrs.has_key? :removal_date
        validate_removal_from_completed_task(attrs[:removal_date], supertask)
        remove on: attrs[:removal_date]
      end
      self.nodes.connect(subtask, supertask)
    end

    def remove(opts={})
      removal_date = opts.fetch :on, Time.current
      assert_removal_date_valid removal_date
      supertask and validate_removal_from_completed_task(removal_date, supertask)
      @removal_date = removal_date
      return self
    end

    def assert_removal_date_valid(removal_date)
      !removed? or raise InvalidRelationError,
        "Couldn't redefine relation removal date"
      removal_date >= addition_date or raise InvalidRelationError,
                    "Relation couldn't be removed earlier than it was created"
    end
    protected :assert_removal_date_valid

    def validate_addition_to_completed_task(addition_date, supertask)
      if (type == :composition && addition_date > supertask.completion_date)
        raise InvalidRelationError, "Couldn't add subtask to completed task"
      end
    end

    def validate_removal_from_completed_task(removal_date, supertask)
      if (type == :composition && removal_date > supertask.completion_date)
        raise InvalidRelationError, "Couldn't remove subtask from completed task"
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
      @old_supertask = self.nodes.parent
      @old_subtask   = self.nodes.child
      self.nodes.disconnect
    end


    def inspect
      id_str = id.nil? ? '' : ":#{id}"
      subtask = self.subtask.inspect +
        (self.subtask.nil? ? " (was #{@old_subtask.inspect})" : '')
      supertask = self.supertask.inspect +
        (self.supertask.nil? ? " (was #{@old_supertask.inspect})" : '')

      "<#{self.class}:#{sprintf('%016x', object_id)}#{id_str} #{type}" \
      " of #{supertask} - #{subtask}>" \
      " effective in #{effective_interval.inspect}"
    end

  end
end
