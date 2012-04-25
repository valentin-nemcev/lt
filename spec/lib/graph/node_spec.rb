require 'spec_helper'

describe Graph::Node do
  it 'should have only one instance method: #edges' do
    subject.instance_methods.should eq([:edges])
  end

  specify '#edges should return edges of extended node' do
    node = Object.new.extend subject
    node.edges.node.should be(node)
  end
end
