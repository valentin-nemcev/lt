class CreateTaskStateRevisions < ActiveRecord::Migration
  def change
    create_table "task_state_revisions" do |t|
      t.references  "task"
      t.string      "state"
      t.datetime    "updated_on"
      t.integer     "sequence_number", :null => false
    end
  end
end
