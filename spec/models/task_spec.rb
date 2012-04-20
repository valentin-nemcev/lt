require 'spec_helper'

describe Task do
  describe 'single task' do
    let(:single_task) { Task.create! }
    subject { single_task }

    context 'after creation' do
      it 'should have creation date' do
        with_frozen_time { |now| single_task.created_on.should eq(now) }
      end

      it 'should not have completion date' do
        single_task.completed_on.should be_nil
      end

      it { should be_actionable }
      it { should_not be_completed }
      it { should_not be_blocked }

      context 'seen from now' do
        it {should be}
      end

      context 'seen from past' do
        subject { single_task; Task.as_of(1.second.ago).first }
        it {should be_nil}
      end
    end

    context 'completed' do
      subject { single_task.complete! }
      it { should be_completed }
      it { should_not be_actionable }
      it 'should have completion date' do
        with_frozen_time { |now| subject.completed_on.should eq(now) }
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
          with_frozen_time { subject.completed_on.should eq(future_date) }
        end
      end

      context 'seen from future date' do
        subject { completed_in_future; Task.as_of(future_date).first }

        it { should be_completed }
      end
    end
  end


  context 'with subtasks (project)' do
    let :project do
      Task.create!.tap { |project|
        2.times { project.subtasks.create! }
      }.reload
    end

    subject { project }

    it { should be_project }
    it { should_not be_actionable }
    it { should_not be_completed }

    it 'could not be completed directly' do
      expect { project.complete! }.to raise_error
    end

    context 'with some subtasks completed' do
      subject { project.subtasks.first.complete!; project }
      it { should_not be_completed }
    end

    context 'with all subtasks completed' do
      let(:with_subtasks_completed) do
        project.tap { |p| p.subtasks.each(&:complete!) }
      end

      context 'and no blocking tasks' do
        subject { with_subtasks_completed }
        it { should be_completed }
        it { should_not be_blocked }
      end

      context 'and with blocking tasks' do
        subject do
          with_subtasks_completed.tap { |p| p.blocking_tasks.create! }
        end

        it { should_not be_completed }
        it { should be_blocked }
      end

      context 'and with completed blocking tasks' do
        subject do
          with_subtasks_completed.tap { |p| p.blocking_tasks.create!.complete! }
        end

        it { should be_completed }
        it { should_not be_blocked }
      end

    end

    context 'with subprojects with subtasks completed' do
      subject do
        Task.create!.tap { |project|
          2.times {
            project.subtasks.create!.tap { |subproject|
              2.times { subproject.subtasks.create!.complete! }
            }
          }
          project.subtasks.create!.complete!
        }.reload
      end

      it { should be_completed }
    end

  end


  context 'blocked task' do
    let(:blocked_task) do
      Task.create!.tap { |blocked_task|
        2.times { blocked_task.blocking_tasks.create! }
      }.reload
    end

    subject { blocked_task }

    it { should be_blocked }
    it { should_not be_actionable }
    it { should_not be_completed }

    context 'with some blocking tasks completed' do
      subject do
        blocked_task.tap { |t| t.blocking_tasks.first.complete! }
      end

      it { should be_blocked }
      it { should_not be_actionable }
    end

    context 'with all blocking tasks completed' do
      subject do
        blocked_task.tap { |t| t.blocking_tasks.each(&:complete!) }
      end

      it { should_not be_blocked }
      it { should be_actionable }
    end

  end

  context 'unscoped' do
    specify 'should behave like scoped to current date' do
      Task.create!
      with_frozen_time do |now|
        unscoped = Task.scoped.first
          scoped = Task.as_of(now).first
        unscoped.current_date.should eq(now)
          scoped.current_date.should eq(now)

        scoped.should eq(unscoped)
      end
    end
  end

end
