module Task
  module AttributeUpdates

    def attribute_updated(name, revision)
      AttributeUpdate.new.tap do |update|
        update.task_id = self.id
        update.attribute_name = name
        update.updated_value = revision.updated_value
      end
    end
  end

  class AttributeUpdate
    attr_accessor :attribute_name, :updated_value, :task_id
  end
end
