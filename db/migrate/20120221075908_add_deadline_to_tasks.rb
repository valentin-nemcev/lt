class AddDeadlineToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :deadline, :date, :null => true
  end
end
