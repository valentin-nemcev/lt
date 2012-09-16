module Task
  class InvalidTaskError < StandardError; end
  class InvalidStateError < InvalidTaskError; end
  #TODO: Remove duplication with ObjectiveRevision
  class StateRevision < Revisions::Revision
    include Persistable

    VALID_STATES = {
        new_task: [:considered, :underway],
        project:  [:considered, :underway, :canceled],
        action:   [:considered, :underway, :canceled, :completed],
      }.freeze

    def self.valid_next_states_for(what)
      what = what.type if what != :new_task
      VALID_STATES.fetch(what)
    end

    attr_reader :state, :updated_on

    def fields
      @fields ||= {}
    end
    protected :fields

    def state
      fields[:state]
    end

    def attribute_name
      :state
    end

    def sequence_number
      fields[:sequence_number]
    end

    def initialize(attrs)
      super
      # fields[:state] = validate_state attrs[:state]
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
