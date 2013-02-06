module Task
  module Attributes
    module ComputedMethods

      extend ActiveSupport::Concern

      module ClassMethods
        def has_computed_attribute(attribute, opts = {}, &block)
          opts[:proc] = block
          computed_attributes_opts[attribute] = opts
        end

        def computed_attributes
          computed_attributes_opts.keys
        end

        def attributes
          computed_attributes | editable_attributes
        end

        def new_computed_attribute_revision(name, attrs)
          computed_attributes_opts.has_key?(name) or
            fail "Unknown computed attribute #{name}"
          attrs[:attribute_name] = name
          ComputedRevision.new(attrs)
        end
      end

      included do |base|
        base.class_attribute :computed_attributes_opts
        self.computed_attributes_opts ||= {}
      end

      def initialize(given_attributes = {})
        super

        @computed_attribute_revisions = {}

        given_attribute_revisions = given_attributes.
          fetch(:all_computed_attribute_revisions, []).
          group_by(&:attribute_name)

        computed_attributes_opts.each_pair do |attr, attr_opts|
          revision_sequence = initialize_computed_revision_sequence attr

          given_attribute_revisions[attr].try do |revisions|
            revision_sequence.set_revisions revisions
          end
        end
      end

      def initialize_computed_revision_sequence(attribute)
        seq = Sequence.new(
          owner: self,
          creation_date: creation_date,
          revision_class: ComputedRevision
        )
        @computed_attribute_revisions[attribute] = seq
      end

      def all_computed_attribute_revisions(*)
        computed_attributes_opts.flat_map do |attr, attr_opts|
          updated_computed_attribute_revisions(attr).to_a
        end
      end

      def last_computed_attribute_revision(args = {})
        attribute = args[:for]
        date      = args.fetch :on
        updated_computed_attribute_revisions(attribute).last_on date
      end


      def computed_attribute_revisions(args = {})
        attribute = args[:for]
        interval  = args[:in] || TimeInterval.for_all_time
        updated_computed_attribute_revisions(attribute).all_in_interval interval
      end

      def updated_computed_attribute_revisions(attribute)
        @computed_attribute_revisions[attribute]
      end

      def computed_attributes_after_creation
        date = self.creation_date
        computed_attributes_opts.flat_map do |attr, attr_opts|
          self.computed_attribute_with_deps(attr, date)
        end
      end

      def computed_attributes_after_attribute_update(revision)
        attribute, date = revision.attribute_name, revision.update_date
        deps_for_attribute(attribute, date).flat_map do |task, attr|
          task.computed_attribute_with_deps(attr, date)
        end
      end

      def computed_attributes_after_relation_update(
        given_rel_type, given_rel_dir, given_date
      )
        deps_for_relation(given_rel_type, given_rel_dir, given_date).
          flat_map do |task, attr|
          task.computed_attribute_with_deps(attr, given_date)
        end
      end

      def deps_for_attribute(given_attribute, given_date)
        computed_attributes_opts.flat_map do |attr, attr_opts|
          depended_on_attributes = attr_opts[:computed_from]
          depended_on_attributes.flat_map do |rel, attrs|
            next unless Array(attrs).include? given_attribute
            rel_tasks = if rel == :self
              [self]
            else
              filtered_relations(
                :on => given_date,
                :for => self.class.reversed_relation(rel)).nodes
            end
            rel_tasks.map{ |rel_task| [rel_task, attr, given_date] }
          end.compact
        end
      end

      def deps_for_relation(given_rel_type, given_rel_dir, given_date)
        computed_attributes_opts.flat_map do |attr, attr_opts|
          depended_on_attributes = attr_opts[:computed_from]
          depended_on_attributes.map do |rel, attrs|
            next if rel == :self
            opts = relation_opts_for(rel)
            unless opts[:type] == given_rel_type &&
                opts[:relation] == given_rel_dir
              next
            end
            [self, attr, given_date]
          end.compact
        end
      end

      def computed_attribute_with_deps(attribute, date)
        [[self, attribute, date]] +
          deps_for_attribute(attribute, date).flat_map do |task, attr|
            task.computed_attribute_with_deps(attr, date)
          end
      end

      def compute_attribute(attribute, date)
        attr_opts = computed_attributes_opts.fetch attribute
        attribute_proc = attr_opts[:proc]
        depended_on_attributes = attr_opts[:computed_from]

        current_values = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        depended_on_attributes.each_pair do |rel, attrs|
          rel_tasks = if rel == :self
            [self]
          else
            filtered_relations(:on => date, :for => rel).nodes
          end
          rel_tasks.each do |task|
            Array(attrs).each do |attr|
              msg = attr == attribute && task == self ?
                :last_editable_attribute_revision : :last_attribute_revision
              revision = task.public_send(msg, :for => attr, on: date)
              value = revision.updated_value if revision
              current_values[rel][attr][task] = value
            end
          end
        end

        proc_arguments = depended_on_attributes.flat_map do |rel, attrs|
          Array(attrs).map do |attr|
            if rel == :self
              current_values[rel][attr].values.first
            else
              current_values[rel][attr].values
            end
          end
        end

        computed_value = attribute_proc.(*proc_arguments, date)

        rev = @computed_attribute_revisions[attribute].new_revision \
          attribute_name: attribute,
          updated_value: computed_value,
          update_date: date
      end
    end
  end
end
