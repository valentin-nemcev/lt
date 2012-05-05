require 'spec_helper'

describe Task::ObjectiveMethods do
  class TaskWithObjectiveMethods < Task::Core
    include Task::ObjectiveMethods
  end

  def create_task(attrs={})
    attrs.reverse_merge! objective: 'Test!'
    create_task_without_objective attrs
  end

  def create_task_without_objective(attrs={})
    TaskWithObjectiveMethods.new attrs
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
