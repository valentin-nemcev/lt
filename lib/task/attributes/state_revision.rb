module Task
  module Attributes
    class StateRevision < EditableRevision
      include Persistable

      VALID_STATES = [:considered, :underway, :canceled, :completed].freeze

      def attribute_name
        :state
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
    class InvalidStateError < Task::Error; end
  end
end
