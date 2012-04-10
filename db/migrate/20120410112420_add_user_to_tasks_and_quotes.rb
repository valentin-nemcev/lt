class AddUserToTasksAndQuotes < ActiveRecord::Migration

  class Task < ActiveRecord::Base; end

  def up
    add_column :tasks, :user_id, :integer, :null => false
    add_column :quotes, :user_id, :integer, :null => false

    user_id = User.first!.id
    Task.reset_column_information
    Task.all.each { |t| t.update_attribute(:user_id, user_id) }
    Quote.reset_column_information
    Quote.all.each { |t| t.update_attribute(:user_id, user_id) }
  end

  def down
    remove_column :tasks, :user_id
    remove_column :quotes, :user_id
  end
end
