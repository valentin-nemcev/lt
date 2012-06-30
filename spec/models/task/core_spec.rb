require 'spec_helper'

describe Task::Core do
  def create_task(attrs={})
    attrs.reverse_merge! objective: 'Test!'
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

    context 'created in past with created_on' do
      subject { create_task created_on: 2.days.ago }
      it 'should have creation date in past', :with_frozen_time do
        subject.created_on.should eq(2.days.ago)
      end
    end

    context 'created in future' do
      subject { create_task on: 2.days.from_now }
      it 'should have effective date in future', :with_frozen_time do
        subject.effective_date.should eq(2.days.from_now)
      end
    end


    context 'as of different date' do
      let(:original) { create_task }
      let(:as_of_different_date) { original.as_of 4.hours.from_now }
      it 'should equal to original task' do
        as_of_different_date.should == original
      end
    end
  end


  context 'with blocking tasks' do
    let(:no_completed_tasks) do
      [double('task1', :completed? => false),
        double('task1', :completed? => false)]
    end

    let(:some_completed_tasks) do
      [double('task1', :completed? => true),
        double('task1', :completed? => false)]
    end

    let(:all_completed_tasks) do
      [double('task1', :completed? => true),
        double('task1', :completed? => true)]
    end

    let(:blocked_task) do
      create_task.tap { |t| t.stub subtasks: no_completed_tasks }
    end

    subject { create_task.tap { |t| t.stub subtasks: no_completed_tasks } }
    it { should be_blocked }

    context 'with some blocking tasks completed' do
      subject { create_task.tap { |t| t.stub subtasks: some_completed_tasks } }
      it { should be_blocked }
    end

    context 'with all blocking tasks completed' do
      subject { create_task.tap { |t| t.stub subtasks: all_completed_tasks } }
      it { should_not be_blocked }
    end
  end
end
