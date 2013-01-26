module Task
  module Attributes
    class ObjectiveRevision < EditableRevision
      %w[
        EmptyObjectiveError
      ].each { |error_name| const_set(error_name, Class.new(Error)) }

      include Persistable

      def attribute_name
        :objective
      end


      def normalize_value(objective)
        objective.to_s.strip.gsub(/\s+/, ' ')
      end

      def validate_value(objective)
        if objective.blank?
          raise EmptyObjectiveError.new revision: self, objective: objective
        else
          return objective
        end
      end
    end
  end
end
