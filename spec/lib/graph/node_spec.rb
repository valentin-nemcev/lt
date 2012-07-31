require 'spec_helper'

describe Graph::Node do

  class TestNode
    include Graph::Node
  end

  subject(:node)
  it 'should have only one instance method: #edges' do
    node.public_instance_methods.should eq([:edges])
  end

  specify 'new nodes should have edges' do
    TestNode.new.edges.should be_present
  end

  specify 'dinamically extended nodes should have edges' do
    Object.new.extend(Graph::Node).edges.should be_present
  end

  describe '#edges' do
    it 'should have reference to extended node' do
      node = TestNode.new
      node.edges.node.should be(node)
    end

    context 'for cloned node' do
      let(:original_node) { TestNode.new }
      let(:cloned_node) { original_node.clone }

      it 'should have reference to cloned node' do
        cloned_node.edges.node.should be(cloned_node)
      end
    end

    context 'for dinamically extended cloned node' do
      let(:original_node) { Object.new.extend(Graph::Node) }
      let(:cloned_node) { original_node.clone }

      it 'should have reference to cloned node' do
        cloned_node.edges.node.should be(cloned_node)
      end
    end
  end
end
