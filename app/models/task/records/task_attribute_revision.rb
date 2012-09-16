module Task
  module Records
    class TaskAttributeRevision < ActiveRecord::Base
      self.record_timestamps  = false
      attr_accessible :attribute_name, :updated_value,
        :updated_on, :sequence_number

      belongs_to :task

      def self.save_revisions(task_record, revisions)
        revisions.map{ |rev| save_revision(task_record, rev) }
      end

      def self.save_revision(task_record, revision)
        scope = task_record.attribute_revisions
        if revision.persisted?
          scope.find_by_id! revision.id
        else
          scope.build
        end.tap do |record|
          record.map_from_revision(revision).save!
          revision.id = record.id
        end
      end

      def self.load_revisions(task_record)
        task_record.attribute_revisions.map do |rec|
          ::Task::Base.new_attribute_revision(
            rec.attribute_name.to_sym,
            id:              rec.id,
            updated_value:   rec.updated_value,
            updated_on:      rec.updated_on,
            sequence_number: rec.sequence_number,
          )
        end
      end

      def map_from_revision(revision)
        self.sequence_number = revision.sequence_number
        self.updated_on      = revision.updated_on
        self.attribute_name  = revision.attribute_name.to_s
        self.updated_value   = revision.updated_value
        self
      end
    end
  end
end
