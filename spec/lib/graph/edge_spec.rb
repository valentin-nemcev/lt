require 'spec_helper'

# TODO: Use new rspec named subject everywhere
describe Graph::Edge do
  it 'should have only one instance method: #nodes' do
    subject.instance_methods.should eq([:nodes])
  end

  specify '#nodes should return nodes of extended edge' do
    edge = Object.new.extend subject
    edge.nodes.edge.should be(edge)
  end
end
