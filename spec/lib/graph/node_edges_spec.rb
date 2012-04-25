require 'spec_helper'

describe Graph::NodeEdges do
  it 'should have node' do
    node = Object.new
    edges = described_class.new node
    edges.node.should be(node)
  end
end
