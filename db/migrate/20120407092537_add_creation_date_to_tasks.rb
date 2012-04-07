class AddCreationDateToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, 'created_at',  :datetime, :null => false
  end
end
