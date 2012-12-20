module Task
  module Attributes
  class InvalidStateError < TaskError; end

  class StateRevision < Editable::Revision
    include Persistable

    VALID_STATES = [:considered, :underway, :canceled, :completed].freeze

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

    def normalize_value(state)
      state.to_sym
    end

    def validate_value(state)
      if state.blank?
        raise InvalidStateError, "State is empty"
      elsif !state.in? VALID_STATES
        raise InvalidStateError, "Invalid state: #{state}"
      else
        return state
      end
    end
  end
  end
end
