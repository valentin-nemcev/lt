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
    end

    shared_examples 'two disconnected nodes' do
    end

    context 'connected' do
      before(:each) do
        child.edges.should_receive(:edge_added).with(edge)
        parent.edges.should_receive(:edge_added).with(edge)

        edge.nodes.connect(child, parent)
      end

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

      context 'then disconnected' do
        before(:each) do
          edge.nodes.disconnect
        end

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
    end
  end

  context 'chain of three connected nodes' do
    let(:edge12) { stub('edge12').extend FakeEdge }
    let(:edge23) { stub('edge23').extend FakeEdge }
    let(:node1)  { stub('node1').extend FakeNode }
    let(:node2)  { stub('node2').extend FakeNode }
    let(:node3)  { stub('node3').extend FakeNode }

    before(:each) do
      edge12.nodes.connect(node2, node1)
      edge23.nodes.connect(node3, node2)
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
        edge31.nodes.connect(node1, node3)
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
end
