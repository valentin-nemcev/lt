module Task
  class InvalidRelationError < StandardError; end;
  class Relation

    include ::Graph::Edge
    include Persistable


    def fields
      @fields
    end

    attr_reader :type, :added_on, :removed_on
    def initialize(attrs={})
      @fields = {}
      self.nodes.parent = attrs.fetch :supertask
      self.nodes.child = attrs.fetch :subtask
      @type = attrs.fetch(:type).to_sym
      now = attrs.fetch(:clock, Time).current
      @added_on = attrs[:on] || attrs[:added_on] || now
      remove on: attrs[:removed_on]
    end

    def remove(opts={})
      removed_on = opts.fetch :on, Time.current
      if removed_on && removed_on < added_on
        raise InvalidRelationError,
          "Relation couldn't be removed earlier than it was created"
      end
      @removed_on = removed_on
      return self
    end

    def supertask
      nodes.parent
    end

    def subtask
      nodes.child
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
      " effective in #{effective_period.inspect}"
    end

  end
end
