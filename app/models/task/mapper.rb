module Task
  class TaskMapperError < StandardError; end;
  class Mapper

    attr_reader :user

    def initialize(opts = {})
      @user = opts.fetch :user
    end

    def store_all(tasks)
      stats = Hash.new { 0 }
      @task_records = {}
      tasks.each do |task|
        stats[:tasks_first_time_persisted] += 1 unless task.persisted?
        task_record = map_task_to_record task
        stats[:task_records_created] += 1 if task_record.new_record?
        stats[:task_records_updated] += 1 if task_record.changed?
        task_record.save!
        task.id = task_record.id
        @task_records[task.id] = task_record
      end
      relations = extract_relations tasks
      relations.each do |relation|
        relation_record = map_relation_to_record relation
        relation_record.save!
        relation.id = relation_record.id
      end
      stats[:tasks_total] = tasks.length
      stats[:relations_total] = relations.length

      stats
    end

    def scope_records(records)
      records.where user_id: user.id
    end

    def get_task_record(task)
      records = case task
                when Project then Records::Project
                when Action  then Records::Action
                else fail TaskMapperError, "Unknown task type: #{task.class}"
                end

      records = scope_records records
      if task.persisted?
        records.find task.id
      else
        records.new
      end

    end

    def map_task_to_record(task)
      get_task_record(task).tap do |task_r|
        task_r.created_on = task.created_on
        if task.respond_to? :completed_on
          task_r.completed_on = task.completed_on
        end
        task_r.objective_revisions = task.objective_revisions.map { |rev|
          map_objective_revision_to_record task_r, rev
        }
      end
    end

    def get_objective_revision_record(task_record, revision)
      records = Records::ObjectiveRevision.where(task: task_record)
      if revision.persisted?
        records.find task.id
      else
        records.new
      end

    end

    def map_objective_revision_to_record(task_record, revision)
      get_objective_revision_record(task_record, revision).tap do |rev_r|
        rev_r.objective = revision.objective
        rev_r.updated_on = revision.updated_on
      end
    end


    def extract_relations(tasks)
      tasks.map(&:relations).reduce(Set.new, &:merge)
    end

    def get_relation_record(relation)
      records = case
                when relation.dependency?  then Records::DependencyRelation
                when relation.composition? then Records::CompositeRelation
                else fail TaskMapperError,
                            "Unknown relation type: #{relation.type}"
                end

      if relation.persisted?
        records.find relation.id
      else
        records.new
      end
    end

    def map_relation_to_record(relation)
      get_relation_record(relation).tap do |relation_r|
        relation_r.added_on = relation.added_on
        relation_r.removed_on = relation.removed_on
        relation_r.supertask = @task_records[relation.supertask.id]
        relation_r.subtask = @task_records[relation.subtask.id]
      end
    end

  end
end
