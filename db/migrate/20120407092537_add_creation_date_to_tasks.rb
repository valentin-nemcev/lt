class AddCreationDateToTasks < ActiveRecord::Migration
  class Task < ActiveRecord::Base; end

  def up
    add_column :tasks, :created_at, :datetime, :null => false

    Task.reset_column_information
    Task.all.each do |task|
      task.update_attribute :created_at, Time.now
    end
  end

  def down
    remove_column :tasks, :created_at
  end
end
