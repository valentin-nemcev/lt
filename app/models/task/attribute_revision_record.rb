module Task
  class AttributeRevisionRecord < ActiveRecord::Base
    self.table_name = 'task_attribute_revisions'
    self.record_timestamps  = false
    attr_accessible :attribute_name, :updated_value,
      :update_date, :sequence_number

    belongs_to :task, :class_name => ::Task::Record,
      :foreign_key => :task_id,
      :inverse_of => :attribute_revisions

    def self.save_revisions(task_record, revisions)
      revisions.map{ |rev| save_revision(task_record, rev) }.compact
    end

    def self.save_revision(task_record, revision)
      scope = task_record.attribute_revisions
      return if revision.persisted?
      scope.build.tap do |record|
        record.map_from_revision(revision)
        record.save! if record.changed?
        revision.id = record.id
      end
    end

    def self.load_revisions(task_record)
      task_record.attribute_revisions.map do |rec|
        ::Task::Base.new_attribute_revision(
          rec.attribute_name.to_sym,
          id:              rec.id,
          updated_value:   rec.updated_value,
          update_date:     rec.update_date,
          sequence_number: rec.sequence_number,
        )
      end
    end

    def map_from_revision(revision)
      self.sequence_number = revision.sequence_number
      self.update_date     = revision.update_date
      self.attribute_name  = revision.attribute_name.to_s
      self.updated_value   = revision.updated_value
      self
    end
  end
end
