module Graph
  module Node

    def edges
      @edges ||= NodeEdges.new self
    end

  end
end
