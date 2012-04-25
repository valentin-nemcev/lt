module Graph
  class NodeEdges

    attr_reader :node
    attr_accessor :direction

    def initialize(node, filters=[])
      @node = node
      @edges = Set.new
      @filters = Set.new filters
    end

    include Enumerable

    def each(*args, &block)
      @edges.select do |edge|
        if direction == :descending
          edge.nodes.parent.equal? self.node
        elsif direction == :ascending
          edge.nodes.child.equal? self.node
        else
          true
        end
      end.each *args, &block
    end

    def add_ascending edge
      if @edges.add? edge
        edge.nodes.child = node
      end
    end

    def add_descending edge
      if @edges.add? edge
        edge.nodes.parent = node
      end
    end

    def ascending
      self.clone.tap { |c| c.direction = :ascending }
    end

    def descending
      self.clone.tap { |c| c.direction = :descending }
    end

    def nodes
      self.flat_map do |edge|
        [edge.nodes.parent, edge.nodes.child].reject { |n| n.equal? self.node }
      end
    end

  end

end
