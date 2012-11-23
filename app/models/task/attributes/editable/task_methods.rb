module Task
  module Attributes
  module Editable
  module TaskMethods

    extend ActiveSupport::Concern

    module ClassMethods
      def has_editable_attribute(attr_name, opts = {})
        editable_attributes_opts[attr_name] = opts
      end

      def editable_attributes
        editable_attributes_opts.keys
      end

      def new_attribute_revision(name, attrs)
        editable_attributes_opts.fetch(name).fetch(:revision_class).new(attrs)
      end
    end

    included do |base|
      base.class_attribute :editable_attributes_opts
      self.editable_attributes_opts ||= {}
    end


    def initialize(given_attributes = {})
      super

      @attribute_revisions = {}

      given_attribute_revisions = given_attributes.
        fetch(:all_editable_attribute_revisions, []).group_by(&:attribute_name)

      editable_attributes_opts.each_pair do |attr, attr_opts|
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

    def all_editable_attribute_revisions(*)
      @attribute_revisions.values.flat_map(&:to_a)
    end

    def editable_attribute_revisions(args = {})
      @attribute_revisions[args.fetch :for].
        all_in_interval(args.fetch :in).to_a
    end

    def last_editable_attribute_revision(args = {})
      @attribute_revisions[args.fetch :for].last_before args.fetch :before
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
  end
end
