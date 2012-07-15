require 'spec_helper'

# TODO: Use new rspec named subject everywhere
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

  context 'with empty objective revisions list' do
    it 'should raise error' do
      expect {
        create_task_without_objective objective_revisions: []
      }.to raise_error Task::InvalidTaskError
    end
  end

  # TODO: Replace date "literals" with lets
  context 'with objective revisions passed on creation' do
    let(:revisions) do
      [
        Task::ObjectiveRevision.new('first', 4.hours.ago),
        Task::ObjectiveRevision.new('second', 3.hours.ago),
      ]
    end
    let(:with_objective_revisions) do
      create_task_without_objective(objective_revisions: revisions, on: 4.hours.ago)
    end

    it 'should have objective revision history', :with_frozen_time do
      with_objective_revisions.objective_revisions.to_a.should =~ revisions
    end

    it 'should not allow objective updates before task was created' do
      revision = Task::ObjectiveRevision.new 'rev', 1.hour.ago
      expect do
        task = create_task_without_objective objective_revisions: [revision]
      end.to raise_error Task::InvalidTaskError
    end

  end

  context 'with objective revisions' do
    let(:with_objective_revisions) do
      create_task(objective: 'first', on: 4.hours.ago).tap do |t|
        t.update_objective 'second', on: 2.hours.from_now
      end
    end
    subject { with_objective_revisions }

    it 'should have objective revision history', :with_frozen_time do
      revs = subject.objective_revisions
      revs.should have(2).revisions

      rev = revs.next
      rev.objective.should eq('first')
      rev.updated_on.should eq(4.hours.ago)

      rev = revs.next
      rev.objective.should eq('second')
      rev.updated_on.should eq(2.hours.from_now)
    end

    context 'seen from now' do
      subject { with_objective_revisions }
      it 'should have old objective' do
        subject.objective.should eq('first')
      end

      it 'should have all revisions' do
        subject.objective_revisions.should have(2).revisions
      end
    end

    context 'seen from future date' do
      subject { with_objective_revisions.as_of 2.hours.from_now }
      it 'should have new objective' do
        subject.objective.should eq('second')
      end
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
