module Graph
  module Node

    def edges
      @edges ||= NodeEdges.new self
    end

    def initialize_copy(source)
      @edges = source.edges.clone_for_node self
      super
    end

  end
end
