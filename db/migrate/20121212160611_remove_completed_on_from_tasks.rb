class RemoveCompletedOnFromTasks < ActiveRecord::Migration
  def up
    remove_column :tasks, :completed_on
  end

  def down
    add_column :tasks, :completed_on, :datetime
  end
end
