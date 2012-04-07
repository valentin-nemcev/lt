class AddCompletionDateToTasks < ActiveRecord::Migration
  class Task < ActiveRecord::Base; end

  def up
    add_column :tasks, :completed_at, :datetime, :null => true

    Task.reset_column_information
    Task.all.each do |task|
      task.update_attribute :completed_at, Time.now if task.done
    end

    remove_column :tasks, :done
  end

  def down
    add_column :tasks, :done, :boolean, :default => false

    Task.reset_column_information
    Task.all.each do |task|
      done = !task.completed_at.nil? && task.completed_at <= Time.now
      task.update_attribute :done, done
    end

    remove_column :tasks, :completed_at
  end
end
