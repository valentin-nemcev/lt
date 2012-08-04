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

  context 'with empty objective revisions list' do
    it 'should raise error' do
      expect {
        create_task_without_objective objective_revisions: []
      }.to raise_error Task::InvalidTaskError
    end
  end

  context 'with objective revisions passed on creation' do
    let(:task_creation_date) { 4.hours.ago }
    let(:task_update_date) { 3.hours.ago }
    let(:revisions) do
      [
        Task::ObjectiveRevision.new(
          objective: 'first',
          updated_on: task_creation_date,
          sequence_number: 1,
        ),
        Task::ObjectiveRevision.new(
          objective: 'second',
          updated_on: task_update_date,
          sequence_number: 2,
        ),
      ]
    end
    let(:revisions_with_invalid_sns) do
      [
        Task::ObjectiveRevision.new(
          objective: 'first',
          updated_on: task_creation_date,
          sequence_number: 2,
        ),
        Task::ObjectiveRevision.new(
          objective: 'second',
          updated_on: task_update_date,
          sequence_number: 1,
        ),
      ]
    end
    let(:with_objective_revisions) do
      create_task_without_objective(objective_revisions: revisions,
                                    on: task_creation_date)
    end

    it 'should have objective revision history' do
      with_objective_revisions.objective_revisions.to_a.should =~ revisions
    end

    it 'should not allow objective updates before task was created' do
      revision = Task::ObjectiveRevision.new(
        objective: 'rev',
        updated_on: 1.hour.until(task_creation_date),
        sequence_number: 1,
      )
      expect do
       create_task_without_objective objective_revisions: [revision],
         on: task_creation_date
      end.to raise_error Task::InvalidTaskError
    end

    it 'should not allow empty revision list' do
      expect do
        create_task_without_objective objective_revisions: []
      end.to raise_error Task::InvalidTaskError
    end

    it 'should not allow revision list with incorrect sequence numbers' do
      expect do
        create_task_without_objective(
          objective_revisions: revisions_with_invalid_sns,
          on: task_creation_date
        )
      end.to raise_error Task::InvalidTaskError
    end

    it 'should check that creation dates of task and first revision are same' do
      expect do
        create_task_without_objective(objective_revisions: revisions,
                                      on: 1.hour.since(task_creation_date))
      end.to raise_error Task::InvalidTaskError
    end

  end

  context 'with objective revisions' do
    let(:task_creation_date) { 4.hours.ago }
    let(:date_between_creation_and_update) { 3.hours.ago }
    let(:task_update_date) { 2.hours.from_now }
    let(:with_objective_revisions) do
      create_task(objective: 'first', on: task_creation_date).tap do |t|
        t.update_objective 'second', on: task_update_date
      end
    end
    subject(:task) { with_objective_revisions }

    it 'should have objective revision history' do
      revs = task.objective_revisions
      revs.should have(2).revisions

      rev = revs.next
      rev.objective.should eq('first')
      rev.updated_on.should eq(task_creation_date)
      rev.sequence_number.should eq(1)

      rev = revs.next
      rev.objective.should eq('second')
      rev.updated_on.should eq(task_update_date)
      rev.sequence_number.should eq(2)
    end

    context 'seen from now' do
      subject(:task) { with_objective_revisions }
      it 'should have old objective' do
        task.objective.should eq('first')
      end

      it 'should have all revisions' do
        task.objective_revisions.should have(2).revisions
      end
    end

    context 'seen from future date' do
      subject(:task) { with_objective_revisions.as_of task_update_date }
      it 'should have new objective' do
        task.objective.should eq('second')
      end
    end

    it 'should keep order for revisions made on same date' do
      task.update_objective 'second 2', on: task_update_date
      task.as_of(task_update_date).objective.should eq('second 2')
    end

    it 'should not allow objective updates in achronological order' do
      expect do
        task.update_objective 'before first',
          on: 1.hour.until(task_creation_date)
      end.to raise_error Task::InvalidTaskError

      expect do
        task.update_objective 'between first and second',
          on: date_between_creation_and_update
      end.to raise_error Task::InvalidTaskError
    end

  end
end
