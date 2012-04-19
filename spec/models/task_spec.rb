require 'spec_helper'

describe Task do
  describe 'single task' do
    let(:single_task) { Task.create! }
    subject { single_task }

    context 'after creation' do
      it 'should have creation date' do
        with_frozen_time { |now| single_task.created_at.should eq(now) }
      end

      it 'should not have completion date' do
        single_task.completed_at.should be_nil
      end

      it { should be_actionable }
      it { should_not be_completed }

      context 'seen from now' do
        it {should be}
      end

      context 'seen from past' do
        subject { single_task; Task.for_date(1.second.ago).first }
        it {should be_nil}
      end
    end

    context 'completed' do
      subject { single_task.complete! }
      it { should be_completed }
      it { should_not be_actionable }
      it 'should have completion date' do
        with_frozen_time { |now| subject.completed_at.should eq(now) }
      end
    end

    context 'completed, then completion undone' do
      subject { single_task.complete!.undo_complete! }
      it { should_not be_completed }
    end

    context 'completed on future date' do
      let(:future_date) { 1.day.from_now }
      let(:completed_in_future) { single_task.complete!(future_date) }

      context 'seen from now' do
        subject { completed_in_future }

        it { should_not be_completed }
        it 'should have completion date in the future' do
          with_frozen_time { subject.completed_at.should eq(future_date) }
        end
      end

      context 'seen from future date' do
        subject { completed_in_future; Task.for_date(future_date).first }

        it { should be_completed }
      end
    end
  end


  context 'with subtasks (project)' do
    let :project do
      Task.create!.tap do |project|
        2.times { project.subtasks.create! }
        project.reload
      end
    end

    subject { project }

    it { should be_project }
    it { should_not be_actionable }
  end


  context 'unscoped' do
    specify 'should behave like scoped to current date' do
      Task.create!
      with_frozen_time do |now|
        unscoped = Task.scoped.first
          scoped = Task.for_date(now).first
        unscoped.current_date.should eq(now)
          scoped.current_date.should eq(now)

        scoped.should eq(unscoped)
      end
    end
  end

end
