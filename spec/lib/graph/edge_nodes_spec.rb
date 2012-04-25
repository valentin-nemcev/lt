require 'spec_helper'

describe Graph::EdgeNodes do
  it 'should have edge' do
    edge = Object.new
    nodes = described_class.new edge
    nodes.edge.should eq(edge)
  end
end
