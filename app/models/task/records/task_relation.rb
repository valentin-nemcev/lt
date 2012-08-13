module Task
  module Records
    class TaskRelation < ActiveRecord::Base
      self.inheritance_column = nil
      self.record_timestamps  = false

      belongs_to :subtask, class_name: Task
      belongs_to :supertask, class_name: Task
      attr_accessible :type, :added_on, :removed_on, :subtask, :supertask


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
        self.added_on   = relation.added_on
        self.removed_on = relation.removed_on

        self.supertask  = task_records_map[relation.supertask.id]
        self.subtask    = task_records_map[relation.subtask.id]
        self
      end

      def map_to_relation(task_map)
        ::Task::Relation.new(
          id:         self.id,
          type:       self.type,
          supertask:  task_map[self.supertask_id],
          subtask:    task_map[self.subtask_id],
          added_on:   self.added_on,
          removed_on: self.removed_on,
        )
      end
    end
  end
end
