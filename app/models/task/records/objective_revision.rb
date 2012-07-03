module Task::Records
  class ObjectiveRevision < ActiveRecord::Base
    self.table_name = 'task_objective_revisions'
    belongs_to :task
    attr_accessible :objective, :updated_on
  end
end
