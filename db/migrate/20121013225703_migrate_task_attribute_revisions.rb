class MigrateTaskAttributeRevisions < ActiveRecord::Migration
  class TaskObjectiveRevisions < ActiveRecord::Base; end
  class TaskStateRevision < ActiveRecord::Base; end

  class TaskAttributeRevision < ActiveRecord::Base; end

  def up
    # Avoid mass-assignment checks
    ActiveRecord::Base.send(:attr_protected, nil)

    attrs = TaskObjectiveRevisions.all.map { |attr| [attr, :objective] } +
              TaskStateRevision.all.map    { |attr| [attr, :state] }

    attrs.each do |attr, attribute_name|
      attribute_value = attr.public_send attribute_name
      TaskAttributeRevision.create!(
        task_id:         attr.task_id,
        sequence_number: attr.sequence_number,
        updated_on:      attr.updated_on,
        attribute_name:  attribute_name,
        updated_value:   attribute_value,
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
