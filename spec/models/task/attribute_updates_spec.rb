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

  let(:task) { task_class.new }

  let(:task_class) { Class.new }
  before(:each) do
    task_class.instance_eval do
      include Task::AttributeUpdates
    end
  end
end
