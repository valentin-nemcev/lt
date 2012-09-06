module Task
  module Records
    #TODO: Remove duplication with TaskObjectiveRevision
    class TaskStateRevision < ActiveRecord::Base
      belongs_to :task
      attr_accessible :state, :updated_on, :sequence_number

      self.record_timestamps = false

      default_scope order(:sequence_number)


      def self.save_revisions(task_record, revisions)
        revisions.map{ |rev| save_revision(task_record, rev) }
      end

      def self.save_revision(task_record, revision)
        scope = task_record.state_revisions
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
        task_record.state_revisions.map do |rec|
          ::Task::StateRevision.new(
            id:              rec.id,
            updated_value:   rec.state,
            updated_on:      rec.updated_on,
            sequence_number: rec.sequence_number,
          )
        end
      end

      def map_from_revision(revision)
        self.sequence_number = revision.sequence_number
        self.state       = revision.state
        self.updated_on      = revision.updated_on
        self
      end
    end
  end
end

