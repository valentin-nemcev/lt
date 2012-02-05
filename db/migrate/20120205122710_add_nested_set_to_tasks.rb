class AddNestedSetToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :parent_id, :integer
    add_column :tasks, :lft, :integer
    add_column :tasks, :rgt, :integer
    add_column :tasks, :depth, :integer
  end
end
