module Task
  class RelationMapper
    def store(rel)
      recs = Task::Records::CompositeRelation
      rec = if rel.persisted?
              recs.find_or_initialize_by_id(rel.id)
            else
              recs.new
            end

      rec.added_on = rel.added_on
      rec.removed_on = rel.removed_on
      rec.save!
      rel.id = rec.id unless rel.persisted?
    end
  end
end
