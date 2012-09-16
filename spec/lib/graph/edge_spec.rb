require 'spec_helper'

describe Graph::Edge do
  subject(:edge) { described_class }
  it 'should have only one instance method: #nodes' do
    edge.instance_methods.should eq([:nodes])
  end

  specify '#nodes should return nodes of extended edge' do
    edge = Object.new.extend subject
    edge.nodes.edge.should be(edge)
  end
end
