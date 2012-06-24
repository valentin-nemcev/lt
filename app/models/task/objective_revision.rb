module Task
  class InvalidObjectiveError < InvalidTaskError; end
  class ObjectiveRevision
    attr_reader :objective, :updated_on
    def initialize(objective, updated_on)
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
