module Task
  class AttributeRevisionRecord < ActiveRecord::Base
    self.table_name = 'task_attribute_revisions'
    self.record_timestamps  = false
    attr_accessible :attribute_name, :updated_value,
      :update_date, :next_update_date, :sequence_number, :computed

    serialize :updated_value

    scope :computed, where(:computed => true)

    belongs_to :task, :class_name => ::Task::Record,
      :foreign_key => :task_id,
      :inverse_of => :attribute_revisions

    def self.save_revisions(task_record, revisions)
      revisions.map{ |rev| save_revision(task_record, rev) }.compact
    end

    def self.save_revision(revision)
      record = if revision.persisted?
        self.find_by_id! revision.id
      else
        self.new
      end
      record.map_from_revision(revision)
      record.save! if record.changed?
      revision.id = record.id
    end

    def self.load_revisions(task_record)
      task_record.attribute_revisions.map do |rec|
        attrs = {
          id:              rec.id,
          updated_value:   rec.updated_value,
          update_date:     rec.update_date,
          sequence_number: rec.sequence_number,
        }
        if rec.next_update_date?
          attrs[:next_update_date] = rec.next_update_date
        end
        ::Task::Base.new_attribute_revision(
          rec.computed?,
          rec.attribute_name.to_sym,
          attrs
        )
      end
    end

    def map_from_revision(rev)
      self.task_id          = rev.task_id
      self.sequence_number  = rev.sequence_number
      self.update_date      = rev.update_date
      self.next_update_date = rev.has_next? ? rev.next_update_date : nil
      self.attribute_name   = rev.attribute_name.to_s
      self.updated_value    = rev.updated_value
      self.computed         = rev.computed?
      self
    end
  end
end
