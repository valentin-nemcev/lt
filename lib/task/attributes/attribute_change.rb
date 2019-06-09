module Task
  class Attributes::AttributeChange
    attr_reader :task, :attribute, :date

    def initialize(attrs = {})
      @task      = attrs.fetch(:task)
      @attribute = attrs.fetch(:attribute)
      @date      = attrs.fetch(:date)
    end

    def merge_attrs
      [task, attribute, date]
    end

    def attribute_revision
      @attribute_revision ||= task.compute_attribute(attribute, date)
    end

    def with_dependent_changes(accum = [], level = 0)
      accum << self
      puts "#{' ' * level * 2}#{task.id}:#{attribute}"
      # puts accum.map{ |c| "#{c.task.id}:#{c.attribute}" }.join(' -> ')
      task.changes_after_attribute_update(attribute, date).each do |change|
        change.with_dependent_changes(accum, level + 1)
      end
      accum
    end

    def merge(next_change)
      next_change
    end
  end
end

