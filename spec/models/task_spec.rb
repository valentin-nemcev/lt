require 'spec_helper'

describe Task do

  def create_task(attrs={})
    # attrs.merge! body: 'Test task'
    Task.new attrs
  end

  describe 'without connections' do
    let(:single_task) { create_task }
    subject { single_task }

    context 'after creation' do
      it 'should have creation date', :with_frozen_time do
        single_task.created_on.should eq(Time.current)
      end

      it 'should have effective date same as creation date' do
        single_task.effective_date.should eq(single_task.created_on)
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
        subject { single_task.as_of(1.second.ago) }
        it {should be_nil}
      end

      context 'created in past' do
        subject { create_task on: 2.days.ago }
        it 'should have creation date in past', :with_frozen_time do
          subject.created_on.should eq(2.days.ago)
        end
        it 'should have effective date set to now', :with_frozen_time do
          subject.effective_date.should eq(Time.current)
        end
      end

      context 'created in future' do
        subject { create_task on: 2.days.from_now }
        it 'should have effective date in future', :with_frozen_time do
          subject.effective_date.should eq(2.days.from_now)
        end
      end
    end

    context 'completed' do
      subject { single_task.complete! }
      it { should be_completed }
      it { should_not be_actionable }
      it 'should have completion date', :with_frozen_time do
        subject.completed_on.should eq(Time.current)
      end
    end

    context 'completed before created' do
      it 'should raise error' do
        expect { single_task.complete! on: 1.day.ago }.to raise_error
      end
    end

    context 'completed, then completion undone' do
      subject { single_task.complete!.undo_complete! }
      it { should_not be_completed }
    end

    context 'completed on future date' do
      let(:future_date) { 1.day.from_now }
      let(:completed_in_future) { single_task.complete! on: future_date }

      context 'seen from now' do
        subject { completed_in_future }

        it { should_not be_completed }
        it 'should have completion date in the future', :with_frozen_time do
          subject.completed_on.should eq(future_date)
        end
      end

      context 'seen from future date' do
        subject { completed_in_future.as_of(future_date) }

        it { should be_completed }
      end
    end
  end


  context 'with subtasks (project)', :pending do

    let :project do
      create_task.tap { |project|
        2.times { create_task project: project }
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
        create_task.tap { |project|
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


  context 'blocked task', :pending do
    let(:blocked_task) do
      create_task.tap { |blocked_task|
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
      pending
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
