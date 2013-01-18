class SetNextUpdateDatesForTaskAttributeRevisions < ActiveRecord::Migration
  class TaskAttributeRevisions < ActiveRecord::Base
  end

  def up
    TaskAttributeRevisions.order(
      :task_id,
      :computed,
      :attribute_name,
      :update_date,
      :sequence_number
    ).all.chunk do |rev|
      [rev.task_id, rev.computed, rev.attribute_name]
    end.each do |_, revs|
      revs.each_cons(2) do |prev_r, next_r|
        prev_r.next_update_date = next_r.update_date
        prev_r.save!
      end
      revs.last.try do |last_r|
        last_r.next_update_date = nil
        last_r.save!
      end
    end
  end


  def down
  end
end
