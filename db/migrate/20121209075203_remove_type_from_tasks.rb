class RemoveTypeFromTasks < ActiveRecord::Migration
  def up
    remove_column :tasks, :type
  end

  def down
    add_column :tasks, :type, :string
  end
end
