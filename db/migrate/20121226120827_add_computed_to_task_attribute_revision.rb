class AddComputedToTaskAttributeRevision < ActiveRecord::Migration
  def change
    add_column :task_attribute_revisions, :computed, :boolean, :null => false
  end
end
