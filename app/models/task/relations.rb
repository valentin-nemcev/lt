module Task
  class Relations < ::Graph::NodeEdges
    class DuplicateRelationError < Task::TaskError
      def initialize existing, duplicate
        @existing, @duplicate = existing, duplicate
      end
      attr_reader :existing, :duplicate

      def message
        ["Duplicate relation:",
          "existing:  #{existing.inspect}",
          "duplicate: #{duplicate.inspect}"].join("\n")
      end
    end

    def edge_added(new_relation)
      check_for_duplication(new_relation)
    rescue Task::TaskError => e
      new_relation.destroy
      raise e
    end

    def check_for_duplication(new_relation)
      # TODO: Improve edge_added and remove this check
      return if new_relation.incomplete?
      duplicated_relation = effective_in(new_relation.effective_period)
        .filter{ |r| r.type == new_relation.type }
        .filter{ |r| r != new_relation }
        .find{ |r|
          r.other_task(self.task) == new_relation.other_task(self.task)
        }
      if duplicated_relation
        raise DuplicateRelationError.new duplicated_relation, new_relation
      end
    end

    alias_method :task, :node
    alias_method :tasks, :nodes

    def effective_in(given_period)
      filter{ |r| r.effective_period.overlaps_with? given_period }
    end

  end
end