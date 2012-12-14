require 'lib/spec_helper'

require 'graph/node_edges'
require 'graph/edge_nodes'

module FakeEdge
  def nodes
    @nodes ||= Graph::EdgeNodes.new self
  end
end

module FakeNode
  def edges
    @edges ||= Graph::NodeEdges.new self
  end
end

describe Graph do
  context 'two nodes' do
    let(:edge)   { stub('edge').extend FakeEdge }
    let(:parent) { stub('parent').extend FakeNode }
    let(:child)  { stub('child').extend FakeNode }

    shared_examples 'two connected nodes' do
      describe 'edge' do
        it 'should have references to child and parent' do
          edge.nodes.parent.should eq(parent)
          edge.nodes.child.should eq(child)
        end
      end

      describe 'parent' do
        it 'should have reference to child via edge' do
          parent.edges.nodes.to_a.should match_array([child])

          nodes = parent.edges.with_indirect.nodes
          nodes.to_a.should match_array([child])

          parent.edges.outgoing.nodes.to_a.should match_array([child])

          nodes = parent.edges.outgoing.with_indirect.nodes
          nodes.to_a.should match_array([child])

          parent.edges.incoming.nodes.should be_empty
        end
      end

      describe 'child' do
        it 'should have reference to parent via edge' do
          child.edges.nodes.to_a.should match_array([parent])

          nodes = child.edges.with_indirect.nodes
          nodes.to_a.should match_array([parent])

          child.edges.incoming.nodes.to_a.should match_array([parent])

          nodes = child.edges.incoming.with_indirect.nodes
          nodes.to_a.should match_array([parent])

          child.edges.outgoing.nodes.should be_empty
        end
      end
    end

    shared_examples 'two disconnected nodes' do
      describe 'edge' do
        it 'should have no references to child and parent' do
          edge.nodes.parent.should be_nil
          edge.nodes.child.should be_nil
        end
      end

      describe 'parent' do
        it 'should have no reference to child via edge' do
          parent.edges.nodes.should be_empty
          parent.edges.with_indirect.nodes.should be_empty
          parent.edges.outgoing.nodes.should be_empty
          parent.edges.incoming.nodes.should be_empty
        end
      end

      describe 'child' do
        it 'should have no reference to parent via edge' do
          child.edges.nodes.should be_empty
          child.edges.with_indirect.nodes.should be_empty
          child.edges.incoming.nodes.should be_empty
          child.edges.outgoing.nodes.should be_empty
        end
      end
    end

    context 'connected via edge' do
      before(:each) do
        edge.nodes.parent = parent
        edge.nodes.child  = child
      end
      include_examples 'two connected nodes'
    end

    context 'connected via nodes' do
      before(:each) do
        parent.edges.add_outgoing edge
        child.edges.add_incoming edge
      end
      include_examples 'two connected nodes'
    end

    context 'connected' do
      before(:each) do
        edge.nodes.parent = parent
        edge.nodes.child  = child
      end

      context 'then disconnected via edge' do
        before(:each) do
          edge.nodes.parent = nil
          edge.nodes.child  = nil
        end
        include_examples 'two disconnected nodes'
      end

      context 'then disconnected via nodes' do
        before(:each) do
          parent.edges.remove_outgoing edge
          child.edges.remove_incoming edge
        end
        include_examples 'two disconnected nodes'
      end
    end
  end

  context 'chain of three connected nodes' do
    let(:edge12) { stub('edge12').extend FakeEdge }
    let(:edge23) { stub('edge23').extend FakeEdge }
    let(:node1)  { stub('node1').extend FakeNode }
    let(:node2)  { stub('node2').extend FakeNode }
    let(:node3)  { stub('node3').extend FakeNode }

    before(:each) do
      edge12.nodes.parent = node1
      edge12.nodes.child  = node2
      edge23.nodes.parent = node2
      edge23.nodes.child  = node3
    end

    describe 'node 1' do
      it 'should have references to indirectly connected edges' do
        node1.edges.with_indirect.to_a.should match_array([edge12, edge23])
        node1.edges.to_a.should match_array([edge12])
        node1.edges.outgoing
          .with_indirect.to_a.should match_array([edge12, edge23])
        node1.edges.incoming.with_indirect.should be_empty
      end

      it 'should have references to indirectly connected nodes' do
        nodes = node1.edges.with_indirect.nodes
        nodes.to_a.should match_array([node2, node3])
      end
    end

    context 'with loop' do
      let(:edge31) { stub('edge31').extend FakeEdge }
      before(:each) do
        edge31.nodes.parent = node3
        edge31.nodes.child  = node1
      end

      describe 'node 1' do
        it 'should have indirect reference to child nodes' do
          edges = node1.edges.with_indirect
          edges.to_a.should match_array([edge12, edge23, edge31])

          edges = node1.edges.outgoing.with_indirect
          edges.to_a.should match_array([edge12, edge23, edge31])

          edges = node1.edges.incoming.with_indirect
          edges.to_a.should match_array([edge12, edge23, edge31])

          node1.edges.to_a.should match_array([edge12, edge31])
        end
        it 'should have references to indirectly connected nodes and self' do
          nodes = node1.edges.with_indirect.nodes.uniq.to_a
          nodes.should match_array([node1, node2, node3])
        end
      end
    end
  end

  context 'node with dangling connection' do
    let(:edge) { stub('edge').extend FakeEdge }
    let(:node) { stub('node').extend FakeNode }

    before(:each) { edge.nodes.parent = node }

    describe 'node' do
      it 'should return its edges without errors' do
        node.edges.to_a.should match_array([edge])
      end

      it 'should return connected nodes without errors' do
        node.edges.nodes.to_a.should match_array([nil])
        node.edges.with_indirect.nodes.to_a.should match_array([nil])
      end
    end
  end
end
