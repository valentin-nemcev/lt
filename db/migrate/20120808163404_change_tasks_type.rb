class ChangeTasksType < ActiveRecord::Migration
  TYPES = [
    %w{Task::Records::Action action},
    %w{Task::Records::Project project},
  ]

  class Task < ActiveRecord::Base
    set_inheritance_column nil
  end

  def up
    Task.all.each do |task|
      task.update_column :type, TYPES.assoc(task.type)[1]
    end
  end

  def down
    Task.all.each do |task|
      task.update_column :type, TYPES.rassoc(task.type)[0]
    end
  end
end
