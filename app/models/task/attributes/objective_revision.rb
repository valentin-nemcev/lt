module Task
  class EmptyObjectiveError < TaskError;
    def message
      'Objective is empty'
    end
  end

  module Attributes
  class ObjectiveRevision < Editable::Revision
    include Persistable

    def attribute_name
      :objective
    end

    def initialize(attrs)
      super
    end


    def validate_objective(objective)
      if objective.blank?
        raise EmptyObjectiveError
      else
        return objective
      end
    end
  end
  end
end