require 'spec_helper'
require 'models/task_factory_helper'

describe Task do
  context 'new' do
    let(:task) { create_task }

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
