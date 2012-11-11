require 'lib/spec_helper'

require 'revisions/revision'
include Revisions

describe Revision do
  subject(:revision) { Revision.new initialize_args}

  let(:initialize_args) { {
    :updated_value => :attr_value,
    :updated_on => :updated_on,
    :sequence_number => :sequence_number_value,
  } }

  context 'with owner passed on creation' do
    before(:each) { initialize_args[:owner] = owner }
    its(:owner) { should eq(owner) }
  end

  context 'with owner' do
    before(:each) { revision.owner = owner }
    its(:owner) { should eq(owner) }

    specify do
      expect{ revision.owner = stub(:new_owner) }.to raise_error(RevisionError)
    end
  end

  describe 'attributes' do
    specify do
      revision.updated_value.should eq(:attr_value)
      revision.updated_on.should eq(:updated_on)
      revision.sequence_number.should eq(:sequence_number_value)
    end
  end

  let(:owner) { stub(:owner) }
end
