class RenameTaskDates < ActiveRecord::Migration
  def change
    rename_column :tasks, :created_at, :created_on
    rename_column :tasks, :completed_at, :completed_on
  end
end
