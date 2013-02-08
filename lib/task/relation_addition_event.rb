module Task
  class RelationAdditionEvent < RelationEvent
    def type
      'relation_addition'
    end

    def id
      super + '-a'
    end

    def date
      relation.addition_date
    end
  end
end
