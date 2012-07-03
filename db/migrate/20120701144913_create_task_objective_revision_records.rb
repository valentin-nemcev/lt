class CreateTaskObjectiveRevisionRecords < ActiveRecord::Migration
  def change
    create_table :task_objective_revisions do |t|
      t.references :task
      t.string :objective
      t.datetime :updated_on
    end
    add_index :task_objective_revisions, :task_id
  end
end
