module Task
  class RelationEvent < Event
    alias_method :relation, :target

    def id
      [relation.id, relation.subtask.id, relation.supertask.id].join('-')
    end

    def as_json(*)
      super.merge \
        :relation_type => relation.type,
        :supertask_id  => relation.supertask.id,
        :subtask_id    => relation.subtask.id
    end
  end
end
