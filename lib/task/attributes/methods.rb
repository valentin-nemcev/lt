module Task
  module Attributes::Methods
    extend ActiveSupport::Concern

    module ClassMethods
      def new_attribute_revision(is_computed, attribute_name, attrs)
        if is_computed
          new_computed_attribute_revision(attribute_name, attrs)
        else
          new_editable_attribute_revision(attribute_name, attrs)
        end
      end
    end

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

    def id_revision
      @id_revision = Struct.new(:updated_value, :previous_value).new(id, id)
    end

    def last_attribute_revision(args = {})
      attr = args[:for]
      computed = self.class.computed_attributes
      editable = self.class.editable_attributes
      return id_revision if attr == :_id
      return last_computed_attribute_revision(args) if computed.include? attr
      return last_editable_attribute_revision(args) if editable.include? attr
    end

    def all_attribute_revisions
      all_editable_attribute_revisions + all_computed_attribute_revisions
    end

    def initialize(attrs = {})
      revs = attrs.
        delete(:all_attribute_revisions){ [] }.group_by(&:computed?)
      attrs[:all_editable_attribute_revisions] = revs[false] || []
      attrs[:all_computed_attribute_revisions] = revs[true]  || []
      super
    end
  end
end
