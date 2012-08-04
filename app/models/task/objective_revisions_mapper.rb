module Task
  class ObjectiveRevisionsMapper

    attr_reader :task_record
    def initialize(task_record)
      @task_record = task_record
    end


    def store_all(objective_revisions)
      objective_revisions.each do |rev|
        recs = task_record.objective_revisions
        rec = if rev.persisted?
                recs.find_or_initialize_by_id(rev.id)
              else
                recs.build
              end

        rec.objective = rev.objective
        rec.updated_on = rev.updated_on
        rec.save!
        rev.id = rec.id unless rev.persisted?
      end
    end

    def fetch_all
      task_record.objective_revisions.map.with_index do |rec, i|
        ObjectiveRevision.new(
          id: rec.id,
          objective: rec.objective,
          updated_on: rec.updated_on,
          sequence_number: i + 1
        )
      end
    end
  end
end
