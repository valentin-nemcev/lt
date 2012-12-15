module Task
  module Records
    class Task < ActiveRecord::Base
      self.inheritance_column = nil
      self.record_timestamps  = false

      belongs_to :user
      has_many :attribute_revisions,
        :class_name => ::Task::Records::TaskAttributeRevision,
        :dependent => :destroy

      has_many :incoming_relations,
        class_name: ::Task::Records::TaskRelation, foreign_key: 'subtask_id',
        :dependent => :destroy
      has_many :outgoing_relations,
        class_name: ::Task::Records::TaskRelation, foreign_key: 'supertask_id',
        :dependent => :destroy

      attr_accessible :user, :creation_date


      scope :for_user, ->(user) { where(user_id: user.id) }

      scope :all_graph_scope
      scope :graph_scope

      def self.relations
        ids = all.map(&:id)
        TaskRelation
          .where('supertask_id IN (:ids) AND subtask_id IN (:ids)', ids: ids)
      end


      def self.save_task(task)
        record = if task.persisted?
          self.find_by_id! task.id
        else
          self.new
        end
        record.map_from_task(task).save!
        task.id = record.id
        record
      end

      def self.load_tasks
        all.map { |rec| rec.map_to_task }
      end

      def map_from_task(task)
        self.creation_date = task.creation_date
        self.attribute_revisions =
          TaskAttributeRevision.save_revisions self,
          task.all_editable_attribute_revisions
        self
      end

      def map_to_task
        ::Task::Base.new(
          id: self.id,
          creation_date: self.creation_date,
          all_editable_attribute_revisions:
            TaskAttributeRevision.load_revisions(self),
        )
      end

      def self.destroy_task(task)
        record = self.find_by_id! task.id
        record.destroy
      end
    end
  end
end
