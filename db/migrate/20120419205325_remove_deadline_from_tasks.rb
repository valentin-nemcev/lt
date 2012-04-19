class RemoveDeadlineFromTasks < ActiveRecord::Migration
  def up
    remove_column :tasks, :deadline
  end

  def down
    add_column :tasks, :deadline, :date, :null => true
  end
end
