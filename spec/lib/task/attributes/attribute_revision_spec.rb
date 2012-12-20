require 'lib/spec_helper'

require 'task'
require 'task/attributes/revision'

describe Task::Attributes::Revision do
  Revision = Task::Attributes::Revision
  subject(:revision) { Revision.new initialize_args}

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
      end.to raise_error(Revision::OwnerError)
    end
  end

  describe 'attributes' do
    specify do
      revision.updated_value.should eq(:attr_value)
      revision.update_date.should eq(:update_date)
    end
  end

  describe '#differs_from?' do
    def create_revision(attr, value)
      revision = described_class.new \
        :updated_value => value,
        :update_date => :update_date
      revision.stub(:attribute_name => attr)
      revision
    end

    specify do
      revision1 = create_revision(:attr1, :attr_value1)
      revision2 = create_revision(:attr2, :attr_value1)
      revision3 = create_revision(:attr2, :attr_value2)
      revision4 = create_revision(:attr2, :attr_value2)

      revision1.should be_different_from(revision2)
      revision2.should be_different_from(revision3)
      revision3.should_not be_different_from(revision4)
    end
  end

  let(:owner) { stub(:owner) }
end
