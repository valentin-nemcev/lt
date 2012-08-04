module Task
  module Records
    class Task < ActiveRecord::Base
      belongs_to :user
      has_many :objective_revisions,
        :class_name => ::Task::Records::ObjectiveRevision,
        :dependent => :destroy

      attr_accessible :user, :created_on

      record_timestamps = false
    end
  end
end
