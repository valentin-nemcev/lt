module Task
  module Attributes
    class StateRevision < EditableRevision
      %w[
        EmptyStateError
        UnknownStateError
      ].each { |error_name| const_set(error_name, Class.new(Error)) }

      include Persistable

      VALID_STATES = [:considered, :underway, :canceled, :done].freeze

      def attribute_name
        :state
      end

      def normalize_value(state)
        state.to_sym
      end

      def validate_value(state)
        if state.blank?
          raise EmptyStateError.new revision: self, state: state
        elsif !state.in? VALID_STATES
          raise UnknownStateError.new revision: self, state: state
        else
          return state
        end
      end
    end
  end
end
