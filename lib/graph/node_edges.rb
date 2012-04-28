module Graph
  class NodeEdges

    attr_reader :node
    attr_accessor :direction, :filters

    def initialize(node, filters=[])
      @node = node
      @edges = Set.new
      @filters = Set.new filters
    end

    def initialize_copy(source)
      super
      @filters = source.filters.clone
    end

    include Enumerable

    def each(*args, &block)
      es = @edges.clone
      case direction
      when :outgoing then es.select!{ |e| e.nodes.parent.equal? self.node }
      when :incoming then es.select!{ |e| e.nodes.child.equal?  self.node }
      end

      filters.each do |filter|
        es.select! &filter
      end

      es.each *args, &block
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


    def filter(&filter)
      self.clone.tap { |c| c.filters << filter }
    end

    def incoming
      self.clone.tap { |c| c.direction = :incoming }
    end

    def outgoing
      self.clone.tap { |c| c.direction = :outgoing }
    end

    def nodes
      self.flat_map do |e|
        case direction
        when :outgoing then e.nodes.child
        when :incoming then e.nodes.parent
        else [e.nodes.child, e.nodes.parent]
        end
      end.uniq
    end
  end
end
