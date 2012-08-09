module Task
  module Records
    class Task < ActiveRecord::Base
      self.inheritance_column = nil
      self.record_timestamps  = false

      belongs_to :user
      has_many :objective_revisions,
        :class_name => ::Task::Records::TaskObjectiveRevision,
        :dependent => :destroy

      attr_accessible :user, :type, :created_on


      scope :for_user, ->(user) { where(user_id: user.id) }

      scope :all_graph_scope
      scope :graph_scope

      def self.relations
        TaskRelation.scoped
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
        self.type = task.type
        self.created_on = task.created_on
        self.objective_revisions =
          TaskObjectiveRevision.save_revisions self, task.objective_revisions
        self
      end

      def map_to_task
        ::Task.new_subtype(self.type,
          id: self.id,
          created_on: self.created_on,
          objective_revisions: TaskObjectiveRevision.load_revisions(self)
        )
      end
    end
  end
end
