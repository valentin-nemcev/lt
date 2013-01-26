module Task
  class Relations < ::Graph::NodeEdges
    %w[
      DuplicateError
      LoopError
    ].each { |error_name| const_set(error_name, Class.new(Error)) }

    def edge_added(new_relation)
      check_for_loop(new_relation)
      check_for_duplication(new_relation)
    rescue Task::Error => e
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
        raise DuplicateError.new \
          existing: duplicated_relation,
          new: new_relation
      end
    end

    def check_for_loop(new_relation)
      new_relation.supertask
      connected = effective_in(new_relation.effective_interval)
        .filter{ |r| r.type == new_relation.type }
        .with_indirect
        .outgoing
        .nodes
        .to_set

      if connected.include? new_relation.supertask
        raise LoopError.new relation: new_relation, tasks_in_loop: connected
      end
    end

    alias_method :task, :node
    alias_method :tasks, :nodes

    def effective_in(given_period)
      filter{ |r| r.effective_in? given_period }
    end
  end
end
