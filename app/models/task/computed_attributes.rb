module Task
  module ComputedAttributes

    extend ActiveSupport::Concern

    module ClassMethods
      def has_computed_attribute(attr_name, opts = {})
      end
    end

    def initialize(attrs = {})
      super
    end

    def computed_attribute_revisions(date = nil)
      []
    end

  end

  class ComputedAttributeRevision
  end
end
