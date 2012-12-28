module Task
  module Attributes
    class ComputedRevision < Revision
      include Persistable
      def initialize(attributes = {})
        @attribute_name = attributes.fetch :attribute_name
        super
      end
      attr_reader :attribute_name

      def computed?
        true
      end
    end
  end
end
