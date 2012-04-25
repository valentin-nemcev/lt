module Graph
  class EdgeNodes
    attr_reader :edge
    def initialize(edge)
      @edge = edge
      @parent = @child = nil
    end

    def child=(node)
      return if @child.equal? node
      @child = node
      node.edges.add_ascending edge
    end

    def child
      @child
    end

    def parent=(node)
      return if @parent.equal? node
      @parent = node
      node.edges.add_descending edge
    end

    def parent
      @parent
    end

  end
end
