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

    def clone_for_node(node)
      clone.tap { |c| c.instance_variable_set :@node, node }
    end


    def unfiltered
      @edges.clone
    end

    def filter_edges!(es, current_node)
      case direction
      when :outgoing then es.select!{ |e| e.nodes.parent == current_node }
      when :incoming then es.select!{ |e| e.nodes.child  == current_node }
      end

      filters.each do |filter|
        es.select! &filter
      end
      return es
    end

    def nodes_and_edges
      visited_edges, visited_nodes = Set.new, Set.new

      paths_to_visit = [[:start, self.node]]
      until paths_to_visit.empty? do
        current_edge, current_node = paths_to_visit.pop # Depth first

        unless current_edge == :start
          visited_nodes << current_node
          visited_edges << current_edge
        end

        edges = if current_node && (current_node == self.node || with_indirect?)
                  filter_edges!(current_node.edges.unfiltered, current_node)
                else [] end

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


    def add_incoming edge
      if @edges.add? edge
        edge.nodes.child = node
      end
    end

    def add_outgoing edge
      if @edges.add? edge
        edge.nodes.parent = node
      end
    end

    def remove_incoming edge
      if @edges.delete? edge
        edge.nodes.child = nil
      end
    end

    def remove_outgoing edge
      if @edges.delete? edge
        edge.nodes.parent = nil
      end
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
