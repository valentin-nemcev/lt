require 'lib/spec_helper'

require 'revisions/revision'
include Revisions

describe Revision do
  subject(:revision) { Revision.new initialize_args}

  let(:initialize_args) { {:updated_value => :attr_value} }

  describe '#intialize' do
  end

  describe '#updated_value' do
    specify do
      revision.updated_value.should eq(:attr_value)
    end
  end
end
