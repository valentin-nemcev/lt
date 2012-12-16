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

    def connect(child, parent)
      !(@child || @parent) or raise 'Edge already connected'
      child.edges.add_edge edge
      parent.edges.add_edge edge
      @child, @parent = child, parent
      child.edges.edge_added edge
      parent.edges.edge_added edge
      self
    end

    def disconnect
      child.edges.remove_edge edge
      parent.edges.remove_edge edge
      @child, @parent = nil, nil
    end
  end
end
