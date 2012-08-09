module Task
  module Records
    class TaskObjectiveRevision < ActiveRecord::Base
      belongs_to :task
      attr_accessible :objective, :updated_on, :sequence_number

      self.record_timestamps = false

      default_scope order(:sequence_number)


      def self.save_revisions(task_record, revisions)
        revisions.map{ |rev| save_revision(task_record, rev) }
      end

      def self.save_revision(task_record, revision)
        scope = task_record.objective_revisions
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
        task_record.objective_revisions.map do |rec|
          ::Task::ObjectiveRevision.new(
            id:              rec.id,
            objective:       rec.objective,
            updated_on:      rec.updated_on,
            sequence_number: rec.sequence_number,
          )
        end
      end

      def map_from_revision(revision)
        self.sequence_number = revision.sequence_number
        self.objective       = revision.objective
        self.updated_on      = revision.updated_on
        self
      end
    end
  end
end
