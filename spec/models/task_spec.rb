require 'spec_helper'

describe Task do
  describe '.create' do
    it 'sets creation date' do
      task = Task.create!
      task.created_at.should be <= DateTime.now
    end
  end

  context 'not completed' do
    subject { Task.create! }
    it { should_not be_completed }
    specify { subject.completed_at.should be_nil }
  end

  context 'completed' do
    subject { Task.create!.complete! }
    it { should be_completed }
    specify { subject.completed_at.should be <= DateTime.now }
  end

  context 'completed on future date' do
    let(:future_date) { DateTime.now + 1.day }
    subject { Task.create!.complete!(future_date)  }
    it { should_not be_completed }
    specify { subject.completed_at.should == future_date }
  end

  context 'completed, then completion undone' do
    subject { Task.create!.complete!.undo_complete! }
    it { should_not be_completed }
    specify { subject.completed_at.should be_nil }
  end


  describe '.for_date' do
    it 'selects tasks that were created after provided date' do
      task_created_at = Task.create!.created_at
      Task.for_date(task_created_at).size.should == 1
      Task.for_date(task_created_at - 1.second).size.should == 0
    end

    it 'returns tasks with completed state relevant to provided date' do
      task = Task.create!
      task_created_at = task.created_at
      task_completed_at = task_created_at + 1.day
      task.complete! task_completed_at

      Task.scoped.first.should_not be_completed

      Task.for_date(task_completed_at).first.should be_completed
      task = Task.for_date(task_completed_at - 1.second).first
      task.should_not be_completed
    end
  end
end
