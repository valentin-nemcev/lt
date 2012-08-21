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
      super
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
      self.nodes.parent = nil
      self.nodes.child = nil
    end


    def inspect
      "<#{self.class}:#{self.id.inspect} #{self.type} of #{self.supertask.inspect} - #{self.subtask.inspect}>"
    end

  end
end
