module Task
  module Attributes
    class ObjectiveRevision < EditableRevision
      include Persistable

      def attribute_name
        :objective
      end


      def normalize_value(objective)
        objective.to_s.strip.gsub(/\s+/, ' ')
      end

      def validate_value(objective)
        if objective.blank?
          raise EmptyObjectiveError
        else
          return objective
        end
      end
    end

    class EmptyObjectiveError < Task::Error;
      def message
        'Objective is empty'
      end
    end
  end
end
