module Graph
  module Edge

    def nodes
      @nodes ||= EdgeNodes.new self
    end

  end
end
