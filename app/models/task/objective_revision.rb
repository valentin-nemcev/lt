module Task
  class InvalidObjectiveError < InvalidTaskError; end
  class ObjectiveRevision
    include PersistenceMethods

    attr_reader :objective, :updated_on

    def fields
      @fields
    end
    protected :fields

    def initialize(objective, updated_on, id = nil)
      @fields = {}
      super id: id
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
