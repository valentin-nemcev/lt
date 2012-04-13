class EnableNullUserIdForQuotesAndTasks < ActiveRecord::Migration
  def up
    change_column :tasks,  :user_id, :integer, :null => true
    change_column :quotes, :user_id, :integer, :null => true
  end

  def down
    change_column :tasks,  :user_id, :integer, :null => false
    change_column :quotes, :user_id, :integer, :null => false
  end
end
