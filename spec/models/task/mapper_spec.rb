require 'spec_helper'

describe 'Task persistance' do

  let(:mapper) { Task::Mapper.new }
  let(:task)  { double("Task",   persisted?: false) }
  let(:task1) { double("Task 1", persisted?: false) }
  let(:task2) { double("Task 2", persisted?: false) }
  let(:persisted_task) {
    double("Persisted task", persisted?: true, id: 1)
  }

  it 'should load and save tasks' do
    mapper.save task.as_null_object
    mapper.load_all.should == [task]
  end

  it 'should load tasks with specified ids' do
    id1 = nil
    task.should_receive('id=').with(anything) { |id| id1 = id }
    mapper.save task
    loaded_task = mapper.load_by_id id1
    loaded_task.should == task
  end


  describe '#save' do
    it 'should assing ids to newly persisted tasks' do
      id1 = id2 = nil
      task1.should_receive('id=').with(anything) { |id| id1 = id }
      task2.should_receive('id=').with(anything) { |id| id2 = id }
      mapper.save task1
      mapper.save task2
      id1.should_not == id2
    end

    it 'should update already persisted tasks' do
      mapper.save persisted_task
      mapper.save persisted_task
      mapper.load_all.should == [persisted_task]
    end

  end

end
