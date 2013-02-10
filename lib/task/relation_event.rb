module Task
  class RelationEvent < Event
    alias_method :relation, :target

    def id
      [relation.id, relation.subtask.id, relation.supertask.id].join('-')
    end

    def attribute_changes
      rel = relation
      ev = self.is_a?(RelationAdditionEvent) ? :added : :removed
      super_revs = rel.supertask.
        computed_attributes_after_relation_update(rel.type, :sub, date, ev)
      sub_revs = rel.subtask.
        computed_attributes_after_relation_update(rel.type, :super, date, ev)
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
