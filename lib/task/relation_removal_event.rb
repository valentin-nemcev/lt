module Task
  class RelationRemovalEvent < RelationEvent
    def type
      'relation_removal'
    end

    def id
      super + '-r'
    end

    def date
      relation.removal_date
    end
  end
end
