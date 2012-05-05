require 'spec_helper'

describe Graph::NodeEdges do
  let(:node) { Object.new }

  it 'should have node' do
    edges = described_class.new node
    edges.node.should be(node)
  end

  describe '#clone_for_node' do
    it 'should return same edges for with reference to new node' do
      new_node = node.clone
      edges = described_class.new node
      edges_for_new_node = edges.clone_for_node new_node
      edges_for_new_node.node.should be(new_node)
    end
  end
end
