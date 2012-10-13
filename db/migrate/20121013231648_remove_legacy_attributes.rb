class RemoveLegacyAttributes < ActiveRecord::Migration
  def change
    drop_table :task_objective_revisions
    drop_table :task_state_revisions
  end
end
