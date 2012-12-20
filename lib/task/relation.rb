module Task
  class InvalidRelationError < TaskError; end;
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
      @removal_date = Time::FOREVER
      remove on: attrs[:removal_date] if attrs.has_key? :removal_date
      self.nodes.connect(attrs.fetch(:subtask), attrs.fetch(:supertask))
    end

    def remove(opts={})
      removal_date = opts.fetch :on, Time.current
      assert_removal_date_valid removal_date
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


    def dependency?
      type == :dependency
    end

    def composition?
      type == :composition
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
