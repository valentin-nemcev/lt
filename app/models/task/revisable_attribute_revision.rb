module Task
  class RevisableAttributeRevision < AttributeRevision
    def initialize(attributes = {})
      super
      @sequence_number = attributes[:sequence_number]
    end

    attr_reader :sequence_number
  end
end
