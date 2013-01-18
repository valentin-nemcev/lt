class AddNextUpdateDateToTaskAttributeRevisions < ActiveRecord::Migration
  def change
    add_column :task_attribute_revisions, :next_update_date, :datetime
  end
end
