class AddIndexToTaskAttributeRevisions < ActiveRecord::Migration
  def change
    add_index :task_attribute_revisions, :task_id
  end
end
