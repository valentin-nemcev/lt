module Task
  class Relations < ::Graph::NodeEdges
    class DuplicateRelationError < TaskError
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
    rescue TaskError => e
      new_relation.destroy
      raise e
    end

    def check_for_duplication(new_relation)
      duplicated_relation = effective_in(new_relation.effective_interval)
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
      filter{ |r| r.effective_in? given_period }
    end

  end
end
