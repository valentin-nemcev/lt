module Task
  module RevisableAttributes

    extend ActiveSupport::Concern

    module ClassMethods
      def has_revisable_attribute(attr_name, opts = {})
        revisable_attributes_opts[attr_name] = opts
      end

      def revisable_attributes
        revisable_attributes_opts.keys
      end
    end

    included do |base|
      base.class_attribute :revisable_attributes_opts
      self.revisable_attributes_opts ||= {}
    end


    def initialize(attrs = {})
      super

      @attribute_revisions = {}
      revisable_attributes_opts.each_pair do |attr, attr_opts|
        @attribute_revisions[attr] = revs = Revisions::Sequence.new(
          created_on: created_on,
          revision_class: attr_opts[:revision_class]
        )

        attrs[:"#{attr}_revisions"].try do |revs_a|
          revs.set_revisions revs_a
        end
        attrs[attr].try { |val| update_attributes attr => val }

        raise MissingAttributeError, attr if revs.empty?

        define_singleton_method(attr) { revs.last.send attr }
      end
    end
    attr_accessor :attribute_revisions

    def update_attributes(attrs = {})
      attrs.map do |name, val|
        rev = @attribute_revisions[name].new_revision(
          updated_value: val,
          updated_on: effective_date)
        attribute_updated name, rev
      end
    end
  end


  class MissingAttributeError < TaskError
    def initialize(attr)
      @attr = attr
    end

    def message
      "Missing #{@attr} value or missing or empty attribute revisions"
    end
  end
end
