module Task
  module Attributes
  module TaskMethods
    def attribute_revisions(args = {})
      interval = args[:in]
      computed = self.class.computed_attributes
      editable = self.class.editable_attributes
      computed.flat_map{ |attr|
        computed_attribute_revisions for: attr, in: interval
      } + (editable - computed).flat_map{ |attr|
        editable_attribute_revisions for: attr, in: interval
      }
    end
  end
  end
end
