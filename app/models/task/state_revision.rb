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

    def attribute_name
      :state
    end

    def initialize(attrs)
      super
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
