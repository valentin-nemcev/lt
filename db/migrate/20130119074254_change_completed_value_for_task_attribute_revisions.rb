class ChangeCompletedValueForTaskAttributeRevisions < ActiveRecord::Migration
  class TaskAttributeRevisions < ActiveRecord::Base
    serialize :updated_value
  end

  def up
    updated = 0
    TaskAttributeRevisions
      .where(:attribute_name => ['state', 'computed_state'])
      .all.each do |rev|
        next unless rev.updated_value == :completed
        rev.updated_value = :done
        rev.save!
        updated += 1
      end

    say "Revisions updated: #{updated}"
  end

  def down
  end
end
