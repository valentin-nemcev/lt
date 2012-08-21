module Task
  class InvalidTaskError < StandardError; end
  class InvalidStateError < InvalidTaskError; end
  #TODO: Remove duplication with ObjectiveRevision
  class StateRevision
    include PersistenceMethods

    attr_reader :state, :updated_on

    def fields
      @fields ||= {}
    end
    protected :fields

    def state
      fields[:state]
    end

    def updated_on
      fields[:updated_on]
    end

    def sequence_number
      fields[:sequence_number]
    end

    def initialize(attrs)
      super
      fields[:state] = validate_state attrs[:state]
      fields[:updated_on] = attrs.fetch :updated_on
      fields[:sequence_number] = attrs.fetch :sequence_number
    end

    #TODO: Whitelisting states, validation of state for tasks and projects
    def validate_state(state)
      if state.blank?
        raise InvalidStateError, "State is empty"
      else
        return state
      end
    end

  end
end
