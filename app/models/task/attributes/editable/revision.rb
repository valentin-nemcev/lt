module Task
  module Attributes
    module Editable
      class Revision < Attributes::Revision
        def initialize(attributes = {})
          super
          @sequence_number = attributes[:sequence_number]
        end

        attr_reader :sequence_number
      end
    end
  end
end
