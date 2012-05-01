require 'spec_helper'

describe Task::Task do
  def create_task(attrs={})
    attrs.reverse_merge! objective: 'Test!'
    create_task_without_objective attrs
  end

  def create_task_without_objective(attrs={})
    described_class.new attrs
  end

  context 'new' do
    let(:task) { create_task }
    subject { task }

    it 'should have creation date', :with_frozen_time do
      task.created_on.should eq(Time.current)
    end

    it 'should have effective date same as creation date' do
      task.effective_date.should eq(task.created_on)
    end

    context 'seen from now' do
      it {should be}
    end

    context 'seen from past' do
      subject { task.as_of(1.second.ago) }
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


    context 'with objective' do
      let(:task_with_objective) { create_task objective: 'Task objective' }
      it 'should have objective attribute' do
        task_with_objective.objective.should eq('Task objective')
      end
    end

    context 'without objective' do
      it 'should raise error' do
        expect {
          create_task_without_objective
        }.to raise_error Task::InvalidTaskError
      end
    end

    context 'with updated objective' do
      let(:future_date) { 1.day.from_now }
      let(:updated_in_future) do
        task = create_task objective: 'Old objective'
        task.update_objective 'New objective', on: future_date
      end

      context 'seen from now' do
        subject { updated_in_future }
        it 'should have old objective' do
          subject.objective.should eq('Old objective')
        end
      end

      context 'seen from future date' do
        subject { updated_in_future.as_of future_date }
        it 'should have new objective' do
          subject.objective.should eq('New objective')
        end
      end
    end

    context 'with objective revisions' do
      subject do
        create_task(objective: 'first', on: 4.hours.ago).tap do |t|
          t.update_objective 'second', on: 2.hours.ago
        end
      end

      it 'should have objective revision history', :with_frozen_time do
        revs = subject.objective_revisions
        revs.should have(2).revisions

        revs.first.objective.should eq('first')
        revs.first.updated_on.should eq(4.hours.ago)

        revs.second.objective.should eq('second')
        revs.second.updated_on.should eq(2.hours.ago)
      end

      it 'should not allow objective updates in achronological order' do
        task = subject
        expect do
          task.update_objective 'before first', on: 5.hours.ago
          task.update_objective 'between first and second', on: 3.hours.ago
        end.to raise_error Task::InvalidTaskError
      end
    end

  end

  context 'with sub and supertasks' do
    let(:project1)   { create_task }
    let(:project2)   { create_task }
    let(:dependent1) { create_task }
    let(:dependent2) { create_task }
    let(:blocking1)  { create_task }
    let(:blocking2)  { create_task }
    let(:component1) { create_task }
    let(:component2) { create_task }
    subject do
      create_task.tap do |t|
        t.add_project project1
        t.add_project project2
        t.add_dependent_task dependent1
        t.add_dependent_task dependent2
        t.add_blocking_task blocking1
        t.add_blocking_task blocking2
        t.add_component_task component1
        t.add_component_task component2
      end
    end

    it 'has #supertasks' do
      subject.supertasks.to_a.should =~ [project1, project2, dependent1, dependent2]
    end

    it 'has #dependent_tasks' do
      subject.dependent_tasks.to_a.should =~ [dependent1, dependent2]
    end

    it 'has #projects' do
      subject.projects.to_a.should =~ [project1, project2]
    end

    it 'has #subtasks' do
      subject.subtasks.to_a.should =~ [blocking1, blocking2, component1, component2]
    end

    it 'has #blocking_tasks' do
      subject.blocking_tasks.to_a.should =~ [blocking1, blocking2]
    end

    it 'has #component_tasks' do
      subject.component_tasks.to_a.should =~ [component1, component2]
    end
  end

  context 'with blocking tasks' do
    let(:blocked_task) do
      create_task.tap { |blocked_task|
        2.times { blocked_task.add_blocking_task create_task }
        blocked_task.blocking_tasks.each{ |t| t.stub :completed? => false }
      }
    end

    subject { blocked_task }

    it { should be_blocked }

    context 'with some blocking tasks completed' do
      subject do
        blocked_task.tap { |t| t.blocking_tasks.first.stub :completed? => true }
      end

      it { should be_blocked }
    end

    context 'with all blocking tasks completed' do
      subject do
        blocked_task.tap do |blocked|
          blocked.blocking_tasks.each{ |t| t.stub :completed? => true }
        end
      end

      it { should_not be_blocked }
    end

  end

end
