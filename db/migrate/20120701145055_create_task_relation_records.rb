class CreateTaskRelationRecords < ActiveRecord::Migration
  def change
    create_table :task_relations do |t|
      t.references :subtask
      t.references :supertask
      t.string :type
      t.datetime :added_on
      t.datetime :removed_on
    end
    add_index :task_relations, :subtask_id
    add_index :task_relations, :supertask_id
  end
end
