module Task::Attributes
  class AggregateAttributeChange < AttributeChange
    attr_reader :changes

    def initialize(attrs = {})
      super
      @changes = if attrs.has_key? :changes
        attrs.fetch(:changes)
      else
        [[attrs.fetch(:change), attrs.fetch(:changed_task)]]
      end
    end

    def attribute_revision
      @attribute_revision ||=
        task.compute_aggregate_attribute(attribute, date, merged_changes)
    end

    def merged_changes
      changes.
        reverse.
        each_with_object(Hash.new { |h, k| h[k] = [] }) \
        do |(change, task), merged_changes|
          merged_changes[task].push(change)
        end.
        map do |task, changes|
          change = changes.reverse.reduce do |(prev_change, _), (change, _)|
            if [prev_change, change].to_set == [:add, :remove].to_set
              :noop
            else
              change
            end
          end
          [change, task]
        end.
        reverse
    end

    def merge(next_change)
      self.class.new \
        :task => task,
        :attribute => attribute,
        :date => date,
        :changes => changes + next_change.changes
    end
  end
end
