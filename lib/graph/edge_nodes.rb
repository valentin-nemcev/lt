module Graph
  class EdgeNodes
    def initialize(edge)
      @edge = edge
    end
    attr_reader :edge, :child, :parent

    def other(node)
      if child == node
        parent
      elsif parent == node
        child
      end
    end

    def child=(node)
      return if @child == node
      if node.present?
        node.edges.add_incoming edge
      else
        @child.edges.remove_incoming edge
      end
      @child = node
    end

    def parent=(node)
      return if @parent == node
      if node.present?
        node.edges.add_outgoing edge
      else
        @parent.edges.remove_outgoing edge
      end
      @parent = node
    end
  end
end
