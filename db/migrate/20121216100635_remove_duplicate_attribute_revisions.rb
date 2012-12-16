class RemoveDuplicateAttributeRevisions < ActiveRecord::Migration
  class TaskAttributeRevisions < ActiveRecord::Base
  end

  def up
    revs = TaskAttributeRevisions.order(:task_id, :attribute_name, :update_date, :sequence_number).all
    dup_count = 0
    all_count = revs.count
    revs.chunk do |rev|
      [rev.task_id, rev.attribute_name, rev.updated_value]
    end.each do |_, same|
      _, *dupes = *same
      dup_count += dupes.count
      dupes.each(&:destroy)
    end

    say "Total revisions before: #{all_count}"
    say "Duplicates destroyed: #{dup_count}"
  end

  def down
  end

end
