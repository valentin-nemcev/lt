module Task
  module Records
    class TaskRelation < ActiveRecord::Base
      self.inheritance_column = nil
      self.record_timestamps  = false

      belongs_to :subtask, class_name: Task
      belongs_to :supertask, class_name: Task
      attr_accessible :type, :addition_date, :removal_date, :subtask, :supertask


      def self.load_relations(task_map)
        all.map { |rec| rec.map_to_relation(task_map) }
      end

      def self.save_relation(relation, task_records_map)
        record = if relation.persisted?
          self.find_by_id! relation.id
        else
          self.new
        end
        record.map_from_relation(relation, task_records_map).save!
        relation.id = record.id
        record
      end

      def map_from_relation(relation, task_records_map)
        self.type       = relation.type
        self.addition_date   = relation.addition_date
        self.removal_date = relation.removed? ? relation.removal_date : nil

        self.supertask  = task_records_map[relation.supertask.id]
        self.subtask    = task_records_map[relation.subtask.id]
        self
      end

      def map_to_relation(task_map)
        attrs = {
          id:         self.id,
          type:       self.type,
          supertask:  task_map[self.supertask_id],
          subtask:    task_map[self.subtask_id],
          addition_date:   self.addition_date,
        }
        attrs[:removal_date] = self.removal_date unless self.removal_date.nil?
        ::Task::Relation.new attrs
      end
    end
  end
end
