require 'lib/spec_helper'

require 'persistable'
require 'models/task'
require 'models/task/core'

describe Task::Core do
  def create_task(attrs={})
    attrs.reverse_merge! objective: 'Test!'
    described_class.new attrs
  end

  context 'new' do
    let(:current_time) { Time.current }
    let(:clock) { stub('Clock', current: current_time) }
    subject(:task) { create_task clock: clock }


    it 'should have current time as creation date' do
      task.created_on.should eq(current_time)
    end

    it 'should have effective date same as creation date' do
      task.effective_date.should eq(task.created_on)
    end

    context 'seen from now' do
      it {should be}
    end

    context 'seen from past' do
      subject { create_task.as_of(1.second.until current_time) }
      it {should be_nil}
    end

    context 'created in past' do
      let(:task_creation_date) { 2.days.ago }
      subject(:task) { create_task on: task_creation_date, clock: clock }

      it 'should have creation date in past' do
        task.created_on.should eq(task_creation_date)
      end

      it 'should have effective date set to now' do
        task.effective_date.should eq(current_time)
      end
    end

    context 'created in past with created_on' do
      let(:task_creation_date) { 2.days.ago }
      subject(:task) { create_task created_on: task_creation_date }
      it 'should have creation date in past' do
        task.created_on.should eq(task_creation_date)
      end
    end

    context 'created in future' do
      let(:task_creation_date) { 2.days.from_now }
      subject(:task) { create_task on: task_creation_date }
      it 'should have effective date in future' do
        task.effective_date.should eq(task_creation_date)
      end
    end


    context 'as of different date' do
      let(:original) { create_task }
      let(:as_of_different_date) { original.as_of 4.hours.from_now }
      it 'should equal to original task' do
        as_of_different_date.should == original
      end
    end

    it 'should not equal to nil' do
      create_task.should_not eq(nil)
    end
  end
end

