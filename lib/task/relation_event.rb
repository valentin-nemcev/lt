module Task
  class RelationEvent < Event
    alias_method :relation, :target

    def id
      [relation.id, relation.subtask.id, relation.supertask.id].join('-')
    end

    def priority
      3
    end

    def attribute_changes
      rel = relation
      change = self.is_a?(RelationAdditionEvent) ? :added : :removed
      super_revs = rel.supertask.
        changes_after_relation_update \
          :type => rel.type,
          :relation => :sub,
          :date => date,
          :change => change,
          :changed_task => rel.subtask
      sub_revs = rel.subtask.
        changes_after_relation_update \
          :type => rel.type,
          :relation => :super,
          :date => date,
          :change => change,
          :changed_task => rel.supertask
      super_revs + sub_revs
    end

    def as_json(*)
      super.merge \
        :relation_type => relation.type,
        :supertask_id  => relation.supertask.id,
        :subtask_id    => relation.subtask.id
    end
  end
end
