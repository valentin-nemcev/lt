require 'lib/spec_helper'

require 'task/attributes/revision'

describe Task::Attributes::Revision do
  subject(:revision) { described_class.new initialize_args}

  let(:initialize_args) { {
    :updated_value => :attr_value,
    :update_date => :update_date,
  } }

  context 'with owner passed on creation' do
    before(:each) { initialize_args[:owner] = owner }
    its(:owner) { should eq(owner) }
  end

  context 'with owner' do
    before(:each) { revision.owner = owner }
    its(:owner) { should eq(owner) }

    specify do
      expect do
        revision.owner = stub(:new_owner)
      end.to raise_error(Task::Attributes::AttributeRevisionError)
    end
  end

  describe 'attributes' do
    specify do
      revision.updated_value.should eq(:attr_value)
      revision.update_date.should eq(:update_date)
    end
  end

  let(:owner) { stub(:owner) }
end
