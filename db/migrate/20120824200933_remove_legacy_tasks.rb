class RemoveLegacyTasks < ActiveRecord::Migration
  def up
    drop_table "legacy_tasks"
    drop_table "task_dependencies"
  end

  def down
    create_table "legacy_tasks" do |t|
      t.text     "body",         :null => false
      t.integer  "parent_id"
      t.integer  "lft",          :null => false
      t.integer  "rgt",          :null => false
      t.integer  "depth"
      t.datetime "created_on",   :null => false
      t.datetime "completed_on"
      t.integer  "user_id"
    end

    create_table "task_dependencies" do |t|
      t.integer "blocking_task_id",  :null => false
      t.integer "dependent_task_id", :null => false
      t.boolean "direct",            :null => false
      t.integer "count",             :null => false
    end

  end
end
