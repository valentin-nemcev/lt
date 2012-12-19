module Task
  module Attributes
  module TaskMethods
    def attribute_revisions(args = {})
      interval = args[:in]
      computed = self.class.computed_attributes
      editable = self.class.editable_attributes
      attr = args[:for]
      computed = computed.select{ |a| a == attr } if attr
      editable = editable.select{ |a| a == attr } if attr
      computed.flat_map{ |attr|
        computed_attribute_revisions :for => attr, :in => interval
      } + (editable - computed).flat_map{ |attr|
        editable_attribute_revisions :for => attr, :in => interval
      }
    end

    def last_attribute_revision(args = {})
      attr = args[:for]
      computed = self.class.computed_attributes
      editable = self.class.editable_attributes
      return last_computed_attribute_revision(args) if computed.include? attr
      return last_editable_attribute_revision(args) if editable.include? attr
    end
  end
  end
end
