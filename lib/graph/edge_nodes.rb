module Graph
  class EdgeNodes
    attr_reader :edge
    def initialize(edge)
      @edge = edge
    end

    def other(node)
      if child == node
        parent
      elsif parent == node
        child
      end
    end

    def child
      @child
    end

    def parent
      @parent
    end

    def child=(node)
      return if @child == node
      old_node = @child
      @child = node
      if node.present?
        node.edges.add_incoming edge
      else
        old_node.edges.remove_incoming edge
      end
    end

    def parent=(node)
      return if @parent == node
      old_node = @parent
      @parent = node
      if node.present?
        node.edges.add_outgoing edge
      else
        old_node.edges.remove_outgoing edge
      end
    end

  end
end
