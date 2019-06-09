module Task
  module Attributes
    module ComputedMethods

      extend ActiveSupport::Concern

      module ClassMethods
        def has_computed_attribute(attribute, opts = {})
          opts[:aggregate] = false
          computed_attributes_opts[attribute] = opts
        end

        def has_aggregate_computed_attribute(attribute, opts = {})
          opts[:aggregate] = true
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

      def changes_after_creation
        # puts "after create #{self.id}"
        date = self.creation_date
        computed_attributes_opts.flat_map do |attr, attr_opts|
          # puts "after create #{attr_opts[:aggregate] ? 'aggregate' : ''} #{attr}"
          if attr_opts[:aggregate]
            AggregateAttributeChange.new(
              :task      => self,
              :attribute => attr,
              :date      => date,
              :change    => :initial,
              :changed_task => nil
            ).with_dependent_changes
          else
            AttributeChange.new(
              :task => self,
              :attribute => attr,
              :date => date
            ).with_dependent_changes
          end
        end
      end

      def changes_after_attribute_update(given_attribute, given_date)
        # puts "after update #{self.id} #{given_attribute}"
        aggregate, computed = computed_attributes_opts.partition do |_, opts|
          opts[:aggregate]
        end
        aggregate = aggregate.flat_map do |attr, attr_opts|
          attr_opts[:computed_from].
            select { |rel, attr| attr == given_attribute }.
            flat_map do |rel, _|
              filtered_relations(
                :on => given_date,
                :for => self.class.reversed_relation(rel)
              ).tasks.flat_map do |rel_task|
                # puts "after update aggregate #{attr} #{rel_task.id}"
                AggregateAttributeChange.new(
                  :task      => rel_task,
                  :attribute => attr,
                  :date      => given_date,
                  :change    => :change,
                  :changed_task => self
                ).with_dependent_changes
              end
            end
          end
        puts "computed for #{given_attribute}"
        computed = computed.
          select do |attr, attr_opts|
            attr_opts[:computed_from].include? given_attribute
          end.
          flat_map do |attr, attr_opts|
            puts "   #{attr}"
            # puts "after update computed #{attr}"
            AttributeChange.new(
              :task => self,
              :attribute => attr,
              :date => given_date
            ).with_dependent_changes
          end
        aggregate + computed
      end

      def changes_after_relation_update(args = {})
        # puts "after rel up #{self.id} #{args.values_at(:type, :relation)}"
        date = args.fetch(:date)
        computed_attributes_opts.
          select { |attr, attr_opts| attr_opts[:aggregate] }.
          flat_map do |attr, attr_opts|
            attr_opts[:computed_from].
              select do |rel, _|
                relation_opts_for(rel).values_at(:type, :relation) ==
                  args.values_at(:type, :relation)
              end.
              flat_map do |rel, _|
                # puts "after rel up computed #{attr} #{args.fetch(:changed_task).id}"
                AggregateAttributeChange.new(
                  :task => self,
                  :attribute => attr,
                  :date => date,
                  :change => args.fetch(:change),
                  :changed_task => args.fetch(:changed_task)
                ).with_dependent_changes
            end
          end
      end

      def compute_attribute(attribute, date)
        attr_opts = computed_attributes_opts.fetch attribute
        depended_on_attributes = attr_opts[:computed_from]

        attribute_proc = attr_opts[:changed]
        proc_arguments = depended_on_attributes.map do |attr|
          msg = (attr == attribute) ?
            :last_editable_attribute_revision : :last_attribute_revision
          revision = self.public_send(msg, :for => attr, :on => date)
          value = revision.updated_value if revision
        end

        computed_value = self.instance_exec \
          *proc_arguments, date, &attribute_proc

        @computed_attribute_revisions[attribute].new_revision \
          attribute_name: attribute,
          updated_value: computed_value,
          update_date: date
      end

      def compute_aggregate_attribute(attribute, date, changes)
        attr_opts = computed_attributes_opts.fetch attribute

        added_proc = attr_opts[:added]
        removed_proc = attr_opts[:removed]

        depended_on_attr = attr_opts[:computed_from].to_a.first.second

        computed_value = last_attribute_revision(
          :for => attribute,
          :on => date
        ).try(:updated_value)

        changes.each do |change, changed_task|
          changed_task and rev = changed_task.
              last_attribute_revision(:for => depended_on_attr, :on => date)
          case change
          when :initial
            computed_value = attr_opts.fetch(:initial_value)
          when :added
            added_value = rev.updated_value
            computed_value = self.instance_exec \
              computed_value, added_value, &added_proc
          when :removed
            removed_value = rev.updated_value
            computed_value = self.instance_exec \
              computed_value, removed_value, &removed_proc
          when :change
            removed_value = rev.previous_value
            computed_value = self.instance_exec \
              computed_value, removed_value, &removed_proc
            added_value = rev.updated_value
            computed_value = self.instance_exec \
              computed_value, added_value, &added_proc
          end
        end

        @computed_attribute_revisions[attribute].new_revision \
          attribute_name: attribute,
          updated_value: computed_value,
          update_date: date
      end
    end
  end
end
