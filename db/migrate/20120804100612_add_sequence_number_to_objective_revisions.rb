class AddSequenceNumberToObjectiveRevisions < ActiveRecord::Migration

  class TaskObjectiveRevisions < ActiveRecord::Base
  end

  def up
    add_column :task_objective_revisions, :sequence_number, :integer, :null => false
    TaskObjectiveRevisions.order(:task_id, :updated_on)
    .all.group_by(&:task_id).each_pair do |_, revs|
      revs.map.with_index do |rev, i|
        rev.update_column :sequence_number, i + 1
      end
    end
  end

  def down
    remove_column :task_objective_revisions, :sequence_number
  end

end
