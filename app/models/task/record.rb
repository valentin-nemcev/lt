module Task
  class Record < ActiveRecord::Base
    self.table_name = 'tasks'
    self.inheritance_column = nil
    self.record_timestamps  = false

    belongs_to :user
    has_many :attribute_revisions,
      :foreign_key => :task_id,
      :class_name => ::Task::AttributeRevisionRecord,
      :dependent => :destroy

    has_many :incoming_relations,
      class_name: ::Task::RelationRecord, foreign_key: 'subtask_id',
      :dependent => :destroy
    has_many :outgoing_relations,
      class_name: ::Task::RelationRecord, foreign_key: 'supertask_id',
      :dependent => :destroy

    attr_accessible :user, :creation_date


    scope :for_user, ->(user) { where(user_id: user.id) }

    scope :all_graph_scope
    scope :graph_scope

    def self.relations(ids = nil)
      ids ||= all.map(&:id)
      RelationRecord
        .where('supertask_id IN (:ids) AND subtask_id IN (:ids)', ids: ids)
    end

    def self.effective_on(effective_date)
      includes(:attribute_revisions).where(
        'task_attribute_revisions.update_date <= :effective_date AND' \
        ' (:effective_date < task_attribute_revisions.next_update_date' \
        ' OR task_attribute_revisions.next_update_date IS NULL)',
        :effective_date => effective_date)
    end

    def self.destroy_computed_attribute_revisions
      AttributeRevisionRecord.
        where(:task_id => pluck(:id)).computed.delete_all
    end


    def self.save_task(task)
      record = if task.persisted?
        task_records_cache.fetch(task.id) { self.find_by_id! task.id }
      else
        self.new
      end
      record.map_from_task(task)
      record.save! if record.changed?
      task.id = record.id
      record
    end

    def self.task_records_cache
      @task_records_cache ||= {}
    end

    def self.load_tasks
      includes(:attribute_revisions).all.map do |rec|
        task = rec.map_to_task
        task_records_cache[task.id] = rec
        task
      end
    end

    def map_from_task(task)
      self.creation_date = task.creation_date
      AttributeRevisionRecord.save_revisions self,
                                task.all_attribute_revisions
      self
    end

    def map_to_task
      ::Task::Base.new(
        id: self.id,
        creation_date: self.creation_date,
        all_attribute_revisions:
          AttributeRevisionRecord.load_revisions(self),
      )
    end

    def self.destroy_task(task)
      record = self.find_by_id! task.id
      record.destroy
    end
  end
end
