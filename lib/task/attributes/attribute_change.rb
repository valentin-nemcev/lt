module Task
  class Attributes::AttributeChange < Struct.new(:task, :attribute, :date)
    def attribute_revision
      @attribute_revision ||= task.compute_attribute(attribute, date)
    end

    def merge(next_change)
      next_change
    end
  end
end

