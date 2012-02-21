class RemoveTimestampsFromTasks < ActiveRecord::Migration
  def up
    remove_timestamps :tasks
  end

  def down
    add_timestamps :tasks
  end
end
