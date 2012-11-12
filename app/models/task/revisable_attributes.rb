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


    def initialize(given_attributes = {})
      super

      @attribute_revisions = {}

      given_attribute_revisions = given_attributes.
        fetch(:attribute_revisions, []).group_by(&:attribute_name)

      revisable_attributes_opts.each_pair do |attr, attr_opts|
        revision_sequence = initialize_revision_sequence attr, attr_opts

        given_attribute_revisions[attr].try do |revisions|
          revision_sequence.set_revisions revisions
        end

        given_attributes[attr].try do |val|
          update_attributes({attr => val}, on: created_on)
        end

        raise MissingAttributeError, attr if revision_sequence.empty?
      end
    end

    def initialize_revision_sequence(attribute, options)
      @attribute_revisions[attribute] = Revisions::Sequence.new(
        owner: self,
        created_on: created_on,
        revision_class: options[:revision_class]
      )
    end

    def attribute_revisions(*)
      @attribute_revisions.values.flat_map(&:to_a)
    end

    def last_attribute_revision(*)
    end

    def update_attributes(attrs = {}, opts = {})
      attrs.map do |name, val|
        @attribute_revisions[name].new_revision(
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
