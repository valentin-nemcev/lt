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

      def new_attribute_revision(name, attrs)
        revisable_attributes_opts.fetch(name).fetch(:revision_class).new(attrs)
      end
    end

    included do |base|
      base.class_attribute :revisable_attributes_opts
      self.revisable_attributes_opts ||= {}
    end


    def initialize(attrs = {})
      super
      @attribute_revisions = {}
      all_revs_a = attrs.fetch :attribute_revisions, []
      all_revs = all_revs_a.group_by(&:attribute_name)
      revisable_attributes_opts.each_pair do |attr, attr_opts|
        @attribute_revisions[attr] = revs = Revisions::Sequence.new(
          created_on: created_on,
          revision_class: attr_opts[:revision_class]
        )

        all_revs[attr].try do |revs_a|
          revs_a.each{ |rev| rev.owner = self }
          revs.set_revisions revs_a
        end
        attrs[attr].try do |val|
          update_attributes({attr => val}, on: created_on)
        end

        raise MissingAttributeError, attr if revs.empty?

        define_singleton_method(attr) { revs.last.send attr }
      end
    end

    def attribute_revisions
      @attribute_revisions.values.map(&:to_a).inject(&:+)
    end

    def update_attributes(attrs = {}, opts = {})
      attrs.map do |name, val|
        @attribute_revisions[name].new_revision(
          owner: self,
          updated_value: val,
          updated_on: opts.fetch(:on))
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
