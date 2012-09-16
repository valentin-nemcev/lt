require 'lib/spec_helper'

require 'persistable'
require 'models/task'
require 'models/task/attribute_updates'

describe 'Task with attribute updates' do
  describe '#attribute_updated' do
    context 'given attribute revision' do
      let(:revision) { stub('revision', updated_value: :attr_value) }
      before(:each) { task.stub(id: :task_id) }

      describe 'returned attribute update' do
        subject(:update) { task.attribute_updated :attr_name, revision }
        it { should_not be_nil}
        its(:attribute_name) { should eq(:attr_name) }
        its(:updated_value)  { should eq(:attr_value) }
        its(:task_id)        { should eq(:task_id) }
      end
    end

  end

  describe '#updates' do
    subject(:updates) { task.updates }

    context 'without attribute revisions' do
      before(:each) { task.stub attribute_revisions: [] }
      it { should be_empty }
    end

    context 'with attribute revisions' do
      let(:attr_revisions) { [
        stub(:attr_rev1, to_update: :attr_update1),
        stub(:attr_rev2, to_update: :attr_update2),
      ]}
      before(:each) { task.stub attribute_revisions: attr_revisions }
      it { should match_array([:attr_update1, :attr_update2]) }
    end
  end

  describe '#creation' do
    subject(:creation) { task.creation }
    before(:each) { task.stub(id: :task_id, type: :task_type) }
    its(:id) { should eq(:task_id) }
    its(:type) { should eq(:task_type) }
  end

  let(:task) { task_class.new }

  let(:task_class) { Class.new }
  before(:each) do
    task_class.instance_eval do
      include Task::AttributeUpdates
    end
  end
end
