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

      end

      included do |base|
        base.class_attribute :computed_attributes_opts
        self.computed_attributes_opts ||= {}
      end

      def initialize(attrs = {})
        super
      end

      # ↓ Worst code of the year
      Event = Struct.new(:rel, :attr, :task, :date, :task_ev, :value) do
        include Comparable

        def <=> other
          if self.date == other.date
            if    task_ev && value.in?([:beginning, :added])
              -1
            elsif task_ev && value.in?([:ending, :removed])
              +1
            elsif !task_ev && other.task_ev
              (other <=> self) * -1
            else
              0
            end
          else
            fail self.inspect if self.date.nil?
            fail other.inspect if other.date.nil?
            self.date <=> other.date
          end
        end
      end

      def last_computed_attribute_revision(args = {})
        attribute = args[:for]
        date      = args.fetch :before
        opts = computed_attributes_opts.fetch attribute

        attribute_proc = opts[:proc]
        depended_on_attributes = opts[:computed_from]

        current_values = Hash.new
        depended_on_attributes.each_pair do |rel, attrs|
          current_values[rel] = Hash.new
          Array(attrs).each do |attr|
            current_values[rel][attr] = Hash.new
          end

          tasks = rel == :self ? [[self, nil]]
            : last_related_tasks(:for => rel, :before => date)
          tasks.each do |(task, _)|
            Array(attrs).each do |attr|
              msg = attr == attribute && task == self ?
                :last_editable_attribute_revision : :last_attribute_revision
              revision =
                task.public_send(msg, :for => attr, before: date)
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
        computed_value = attribute_proc.(*proc_arguments)

        ComputedRevision.new \
          owner: self,
          attribute_name: attribute,
          updated_value: computed_value,
          update_date: date
      end

      def computed_attribute_revisions(args = {})
        attribute = args[:for]
        interval    = args[:in] || TimeInterval.for_all_time
        opts = computed_attributes_opts.fetch attribute

        attribute_proc = opts[:proc]
        depended_on_attributes = opts[:computed_from]

        current_values = Hash.new
        depended_on_attributes.each_pair do |rel, attrs|
          current_values[rel] = Hash.new
          Array(attrs).each do |attr|
            current_values[rel][attr] = Hash.new
          end
        end

        events = depended_on_attributes.flat_map do |rel, attrs|
          tasks = rel == :self ? [[self, interval]]
            : related_tasks(:for => rel, :in => interval)
          tasks.flat_map do |(task, orig_task_int)|
            task_int = orig_task_int & interval
            Array(attrs).flat_map do |attr|
              msg = attr == attribute && task == self ?
                :editable_attribute_revisions : :attribute_revisions
              evs = task.public_send(
                msg, :for => attr, :in => task_int
              ).map do |rev|
                Event.new rel, attr, task, \
                  rev.update_date, false, rev.updated_value
              end

              task_ev = rel == :self || orig_task_int.beginning &&
                orig_task_int.beginning < interval.beginning ? :beginning : :added
              evs << Event.new(rel, attr, task, task_int.beginning, true, task_ev)

              task_ev = rel == :self || orig_task_int.ending &&
                orig_task_int.ending > interval.ending ? :ending : :removed
              ending = task_int.ending || Time::FOREVER
              evs << Event.new(rel, attr, task, ending, true, task_ev)

              evs.compact
            end
          end
        end
        events = events.sort.chunk(&:date)

        prev_revision = last_computed_attribute_revision \
          :for => attribute, :before => interval.beginning
        prev_value = prev_revision.try(:updated_value)

        events.map do |date, evs|
          task_evs = []
          next if date == Time::FOREVER
          evs.each do |ev|
            if ev.task_ev
              if ev.value.in? [:removed, :ending]
                current_values[ev.rel][ev.attr].delete(ev.task)
              else ev.value.in? [:added, :beginning]
                msg = ev.attr == attribute && ev.task == self ?
                  :last_editable_attribute_revision : :last_attribute_revision
                revision =
                  ev.task.public_send(msg, :for => ev.attr, before: date)
                value = revision.updated_value if revision
                current_values[ev.rel][ev.attr][ev.task] = value
              end
              task_evs << ev.value
            else
              current_values[ev.rel][ev.attr][ev.task] = ev.value
              task_evs << :changed
            end
          end
          next if task_evs.all?{ |ev| ev.in? [:beginning, :ending] }

          proc_arguments = depended_on_attributes.flat_map do |rel, attrs|
            Array(attrs).map do |attr|
              if rel == :self
                current_values[rel][attr].values.first
              else
                current_values[rel][attr].values
              end
            end
          end

          computed_value = attribute_proc.(*proc_arguments)

          next if computed_value == prev_value
          prev_value = computed_value

          ComputedRevision.new \
            owner: self,
            attribute_name: attribute,
            updated_value: computed_value,
            update_date: date
        end.compact
      end
      # ↑ Worst code of the year
    end
  end
end
