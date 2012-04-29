class Task::Dependency < ActiveRecord::Base
  self.table_name = 'task_dependencies'
  attr_accessible :count, :dependent_task_id, :direct, :task_id

  acts_as_dag_links :node_class_name => 'Task::Record',
    :ancestor_id_column => 'blocking_task_id',
    :descendant_id_column => 'dependent_task_id'
end
