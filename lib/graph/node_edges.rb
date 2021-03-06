module Graph
  class NodeEdges

    attr_reader :node

    def initialize(node, filters=[])
      @node = node
      @edges = Set.new
      @filters = Set.new filters
    end

    def initialize_copy(source)
      super
      @filters = source.filters.clone
    end

    def unfiltered
      @edges.clone
    end

    def filter_edges!(edges, current_node)
      case direction
      when :outgoing then edges.select!{ |e| e.nodes.parent == current_node }
      when :incoming then edges.select!{ |e| e.nodes.child  == current_node }
      end

      filters.each { |filter| edges.select! &filter }
      return edges
    end

    def nodes_and_edges
      visited_edges, visited_nodes = Set.new, Array.new

      paths_to_visit = [[:start, self.node]]
      until paths_to_visit.empty? do
        current_edge, current_node = paths_to_visit.pop # Depth first

        unless current_edge == :start
          visited_edges << current_edge
          visited_nodes << current_node
        end

        if current_node == self.node || with_indirect?
          edges = filter_edges!(current_node.edges.unfiltered, current_node)
        else
          next
        end

        connected_paths = edges.map { |e| [e, e.nodes.other(current_node)] }
        unvisited_paths = connected_paths.reject do |e, n|
          visited_edges.include? e
        end

        paths_to_visit.concat unvisited_paths
      end

      [visited_nodes, visited_edges]
    end


    def to_set
      nodes_and_edges[1]
    end

    def to_a
      nodes_and_edges[1].to_a
    end

    def empty?
      to_set.empty?
    end

    include Enumerable

    def each(*args, &block)
      nodes_and_edges[1].each *args, &block
    end

    def nodes
      nodes_and_edges[0]
    end

    def with_nodes
      nodes, edges = nodes_and_edges
      edges.zip(nodes)
    end


    def add_edge edge
      @edges.add edge
    end

    def remove_edge edge
      @edges.delete edge
    end

    def edge_added(edge)
    end



    attr_reader :direction
    def incoming!
      @direction = :incoming
    end

    def outgoing!
      @direction = :outgoing
    end

    attr_reader :filters
    def filter!(&filter)
      @filters << filter
    end

    def with_indirect?
      !!@with_indirect
    end

    def with_indirect!
      @with_indirect = true
    end


    def with_indirect
      self.clone.tap { |c| c.with_indirect! }
    end

    def filter(&filter)
      self.clone.tap { |c| c.filter! &filter }
    end

    def incoming
      self.clone.tap { |c| c.incoming! }
    end

    def outgoing
      self.clone.tap { |c| c.outgoing! }
    end
  end
end
