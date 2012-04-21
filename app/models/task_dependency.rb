class TaskDependency < ActiveRecord::Base
  attr_accessible :count, :dependent_task_id, :direct, :task_id

  acts_as_dag_links :node_class_name => 'TaskRecord',
    :ancestor_id_column => 'blocking_task_id',
    :descendant_id_column => 'dependent_task_id'
end
