module Task
  class InvalidRelationError < StandardError; end;
  class Relation

    include Graph::Edge
    include PersistenceMethods


    def fields
      @fields
    end
    protected :fields

    attr_reader :type, :added_on, :removed_on
    def initialize(attrs={})
      @fields = {}
      super
      self.nodes.parent = attrs.fetch :supertask
      self.nodes.child = attrs.fetch :subtask
      @type = attrs.fetch :type
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


    def dependency?
      type == :dependency
    end

    def composition?
      type == :composition
    end

  end
end
