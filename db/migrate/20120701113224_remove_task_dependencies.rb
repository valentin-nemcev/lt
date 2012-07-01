class RemoveTaskDependencies < ActiveRecord::Migration
  def up
    drop_table "task_dependencies"
  end

  def down
    create_table "task_dependencies" do |t|
      t.integer "blocking_task_id",  :null => false
      t.integer "dependent_task_id", :null => false
      t.boolean "direct",            :null => false
      t.integer "count",             :null => false
    end

  end
end
