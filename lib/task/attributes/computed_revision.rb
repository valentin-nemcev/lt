module Task
  module Attributes
    class ComputedRevision < Revision
      def initialize(attributes = {})
        @attribute_name = attributes.fetch :attribute_name
        super
      end
      attr_reader :attribute_name

      def self.new_id
        @last_id = (@last_id || 0) + 1
      end

      def id
        @id ||= "c#{self.class.new_id}"
      end
    end
  end
end
