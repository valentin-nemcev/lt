module Task
  module Attributes
    module EditableMethods

      extend ActiveSupport::Concern

      module ClassMethods
        def has_editable_attribute(attr_name, opts = {})
          editable_attributes_opts[attr_name] = opts
        end

        def editable_attributes
          editable_attributes_opts.keys
        end

        def new_editable_attribute_revision(name, attrs)
          editable_attributes_opts.fetch(name).fetch(:revision_class).new(attrs)
        end
      end

      included do |base|
        base.class_attribute :editable_attributes_opts
        self.editable_attributes_opts ||= {}
      end

      %w[
        MissingAttributeError
        UpdatingCompletedTaskError
      ].each { |error_name| const_set(error_name, Class.new(Error)) }

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
            update_attributes({attr => val}, on: creation_date)
          end

          if revision_sequence.empty?
            raise MissingAttributeError.new task: self, attribute: attr
          end
        end
      end

      def initialize_revision_sequence(attribute, options)
        @attribute_revisions[attribute] = Sequence.new(
          owner: self,
          creation_date: creation_date,
          revision_class: options[:revision_class]
        )
      end

      def all_editable_attribute_revisions(*)
        @attribute_revisions.values.flat_map(&:to_a)
      end

      def editable_attribute_revisions(args = {})
        interval = args[:in] || TimeInterval.for_all_time
        @attribute_revisions[args.fetch :for].
          all_in_interval(interval).to_a
      end

      def last_editable_attribute_revision(args = {})
        @attribute_revisions[args.fetch :for].last_before args.fetch :before
      end

      def update_attributes(attrs = {}, opts = {})
        update_date = opts.fetch(:on)
        if update_date > self.completion_date
          raise UpdatingCompletedTaskError.new \
            task: self,
            update_date: update_date
        end
        attributes = attrs.map do |name, val|
          @attribute_revisions[name].new_revision(
            updated_value: val,
            update_date: update_date)
        end.compact
        editable_attributes_updated(attributes)
        attributes.collect(&:update_event)
      end

      def editable_attributes_updated(attributes)
      end

      def editable_attribute_events
        @attribute_revisions.values.flat_map(&:to_a).map(&:update_event)
      end
    end
  end
end
