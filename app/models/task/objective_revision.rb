module Task
  class EmptyObjectiveError < TaskError;
    def message
      'Objective is empty'
    end
  end

  class ObjectiveRevision < Revisions::Revision
    include Persistable

    attr_reader :objective, :updated_on

    def fields
      @fields ||= {}
    end
    protected :fields

    def objective
      fields[:objective]
    end

    def updated_on
      fields[:updated_on]
    end

    def sequence_number
      fields[:sequence_number]
    end

    def initialize(attrs)
      super
      # fields[:objective] = validate_objective attrs[:objective]
      fields[:updated_on] = attrs.fetch :updated_on
      fields[:sequence_number] = attrs.fetch :sequence_number
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
