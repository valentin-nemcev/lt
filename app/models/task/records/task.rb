module Task
  module Records
    class Task < ActiveRecord::Base
      belongs_to :user
      has_many :objective_revisions,
        :class_name => ::Task::Records::ObjectiveRevision,
        :dependent => :destroy

      attr_accessible :user, :created_on

      self.record_timestamps = false

      scope :for_user, ->(user) { where(user: user) }

      scope :all_graph_scope

      def self.load_tasks
        []
      end

      def self.relations
        Relation.scoped
      end

    end
  end
end
