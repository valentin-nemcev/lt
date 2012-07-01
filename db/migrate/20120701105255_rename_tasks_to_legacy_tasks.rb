class RenameTasksToLegacyTasks < ActiveRecord::Migration
  def change
    rename_table :tasks, :legacy_tasks
  end

end
