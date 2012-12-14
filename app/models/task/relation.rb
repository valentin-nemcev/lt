module Task
  class InvalidRelationError < StandardError; end;
  class Relation

    def nodes
      @nodes ||= ::Graph::EdgeNodes.new self
    end

    include Persistable


    def other_task(task)
      nodes.other(task)
    end

    attr_reader :type, :added_on, :removed_on
    def initialize(attrs={})
      self.id = attrs[:id]
      @type = attrs.fetch(:type).to_sym
      now = attrs.fetch(:clock, Time).current
      @added_on = attrs[:on] || attrs[:added_on] || now
      @removed_on = Time::FOREVER
      remove on: attrs[:removed_on] if attrs.has_key? :removed_on
      self.nodes.parent = attrs.fetch :supertask
      self.nodes.child = attrs.fetch :subtask
    end

    def remove(opts={})
      removed_on = opts.fetch :on, Time.current
      assert_removed_on_valid removed_on
      @removed_on = removed_on
      return self
    end

    def assert_removed_on_valid(removal_date)
      !removed? or raise InvalidRelationError,
        "Couldn't redefine relation removal date"
      removal_date >= added_on or raise InvalidRelationError,
                    "Relation couldn't be removed earlier than it was created"
    end
    protected :assert_removed_on_valid

    def supertask
      nodes.parent
    end

    def subtask
      nodes.child
    end

    def effective_interval
      TimeInterval.new added_on, removed_on
    end

    def effective_in?(given_time_interval)
      effective_interval.overlaps_with? given_time_interval
    end

    def effective_on?(given_date)
      effective_interval.include? given_date
    end


    def incomplete?
      supertask.nil? or subtask.nil?
    end

    def dependency?
      type == :dependency
    end

    def composition?
      type == :composition
    end

    def removed?
      removed_on != Time::FOREVER
    end


    def destroy
      @old_supertask = self.nodes.parent
      @old_subtask   = self.nodes.child
      self.nodes.parent = nil
      self.nodes.child  = nil
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
