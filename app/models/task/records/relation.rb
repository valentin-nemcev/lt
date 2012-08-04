module Task
  module Records
    class Relation < ActiveRecord::Base
      self.table_name = 'task_relations'
      belongs_to :subtask, class_name: Task
      belongs_to :supertask, class_name: Task
      attr_accessible :added_on, :removed_on

      record_timestamps = false
    end
  end
end
