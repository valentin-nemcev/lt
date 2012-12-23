module Task
  module Attributes
    class EditableRevision < Revision
      include Persistable
      def initialize(attrs = {})
        updated_value = attrs.fetch :updated_value
        updated_value = normalize_value(updated_value)
        validate_value(updated_value)
        attrs[:updated_value] = updated_value
        super
        @sequence_number = attrs[:sequence_number]
      end

      def normalize_value(value)
        value
      end

      def validate_value(value)
      end

      attr_reader :sequence_number
    end
  end
end
