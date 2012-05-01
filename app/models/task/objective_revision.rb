module Task
  class InvalidObjectiveError < InvalidTaskError; end
  class ObjectiveRevision
    attr_reader :task, :objective, :updated_on
    def initialize(task, objective, updated_on)
      @task = task
      @objective = validate_objective objective
      @updated_on = updated_on
    end

    def validate_objective(objective)
      if objective.blank?
        raise InvalidObjectiveError, "Objective is empty"
      else
        return objective
      end
    end

  end
end
