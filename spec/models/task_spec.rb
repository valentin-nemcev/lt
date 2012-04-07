require 'spec_helper'

describe Task do
  describe '.create' do
    it 'sets creation date' do
      task = Task.create
      task.created_at.should be <= Time.now
    end
  end

  context 'not completed' do
    subject { Task.create }
    it { should_not be_completed }
    specify { subject.completed_at.should be_nil }
  end

  context 'completed' do
    subject { Task.create.complete! }
    it { should be_completed }
    specify { subject.completed_at.should be <= Time.now }
  end

  context 'completed, then completion undone' do
    subject { Task.create.complete!.undo_complete! }
    it { should_not be_completed }
    specify { subject.completed_at.should be_nil }
  end

end
