module Task
  class Mapper

    class TaskMapperError < StandardError; end;
    class TaskNotFoundError < TaskMapperError
      def initialize(task_id)
        @task_id = task_id
      end

      def message
        "Task record with id = #{@task_id} was not found"
      end
    end
    attr_reader :user

    def initialize(opts = {})
      @user = opts.fetch :user
    end

    # TODO: Mark protected methods
    def find_record(id)
      scope_records(Records::Task).find_by_id!(id)
    rescue ActiveRecord::RecordNotFound
      raise TaskNotFoundError, id
    end

    def fetch(id)
      map_record_to_task find_record(id)
    end

    def fetch_all
      records = Records::Task
      @task_objects = {}
      tasks = records.all.map do |task_record|
        @task_objects[task_record.id] = map_record_to_task task_record
      end
      cond = 'supertask_id IN (:ids) OR subtask_id IN (:ids)'
      relations = Records::Relation.where(cond, ids: @task_objects.keys)
      relations.all.each do |relation_record|
        map_record_to_relation relation_record
      end
      return tasks
    end

    def destroy(task)
      raise TaskMapperError, "Task is not persisted" if task.id.nil?
      find_record(task.id).destroy
      task.id = nil
      return self
    end

    def store(task)
      attrs = { created_on: task.created_on }
      task_record = scope_records(Records::Action).new attrs
      o_revs_mapper = ObjectiveRevisionsMapper.new task_record
      o_revs_mapper.store_all task.objective_revisions
      task_record.save!
      task.id = task_record.id
      return self
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
      records.where(user_id: user.id).includes(:objective_revisions)
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

    def map_record_to_task(task_record)
      task_type = case task_record
                  when Records::Project then Project
                  when Records::Action  then Action
                  else fail TaskMapperError,
                    "Unknown task record type: #{task_record.class}"
                  end
      task = task_type.new(
        id: task_record.id,
        created_on: task_record.created_on,
        objective_revisions: task_record.objective_revisions.map { |rev_r|
          map_record_to_objective_revision rev_r
        }
      )
      if task.respond_to? :completed_on
        task.completed_on = task_record.completed_on
      end
      return task

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

    def map_record_to_objective_revision(rev_r)
      ObjectiveRevision.new rev_r.objective, rev_r.updated_on, rev_r.id
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

    def map_record_to_relation(relation_r)
      rel_type = case relation_r
                 when Records::CompositeRelation  then :composition
                 when Records::DependencyRelation then :dependency
                 else fail TaskMapperError,
                   "Unknown relation record type: #{relation_r.class}"
                 end
      Relation.new(
        type: rel_type,
        added_on: relation_r.added_on,
        removed_on: relation_r.removed_on,
        subtask: @task_objects[relation_r.subtask_id],
        supertask: @task_objects[relation_r.supertask_id],
      )
    end

  end
end
