module Task
  class ObjectiveRevisionsMapper

    attr_reader :task_record
    def initialize(task_record)
      @task_record = task_record
    end


    def store_all(objective_revisions)
      objective_revisions.each do |rev|
        task_record.objective_revisions.build do |rec|
          rec.objective = rev.objective
          rec.updated_on = rev.updated_on
        end
      end
    end


  end
end
