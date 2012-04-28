require 'spec_helper'

describe Graph do
  context 'two nodes' do
    let(:edge)   { Object.new.extend Graph::Edge }
    let(:parent) { Object.new.extend Graph::Node }
    let(:child)  { Object.new.extend Graph::Node }

    shared_examples 'two connected nodes' do
      describe 'edge' do
        it 'should have references to child and parent' do
          edge.nodes.parent.should eq(parent)
          edge.nodes.child.should eq(child)
        end
      end

      describe 'parent' do
        it 'should have reference to child via edge' do
          parent.edges.nodes.should include(child)
          parent.edges.outgoing.nodes.should include(child)
          parent.edges.incoming.nodes.should be_empty
        end
      end

      describe 'child' do
        it 'should have reference to parent via edge' do
          child.edges.nodes.should include(parent)
          child.edges.incoming.nodes.should include(parent)
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
  end
end
