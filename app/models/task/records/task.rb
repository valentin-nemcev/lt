module Task::Records
  class Task < ActiveRecord::Base
    belongs_to :user
    has_many :objective_revisions,
      :class_name => ObjectiveRevision, :dependent => :destroy

    attr_accessible :created_on
  end
end
