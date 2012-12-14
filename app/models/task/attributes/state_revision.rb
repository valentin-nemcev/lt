module Task
  module Attributes
  class InvalidTaskError < StandardError; end
  class InvalidStateError < InvalidTaskError; end

  class StateRevision < Editable::Revision
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

    def validate_state(state)
      if state.blank?
        raise InvalidStateError, "State is empty"
      else
        return state
      end
    end
  end
  end
end
