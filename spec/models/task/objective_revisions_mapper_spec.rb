require 'spec_helper'

describe Task::ObjectiveRevisionsMapper do

  describe '#store_all' do
    context 'new task record' do
      let(:new_task_record) { Task::Records::Task.new }
      let(:mapper) { described_class.new new_task_record }

      let(:objective_revisions) do
        [1..3].map do |i|
          stub('ObjectiveRevision').as_null_object
        end
      end

      it 'stores all revisions' do
        mapper.store_all objective_revisions
        expected_count = new_task_record.objective_revisions.size
        expected_count.should eq(objective_revisions.count)
      end

      let(:test_objective) { 'Test objective' }
      let(:test_updated_on) { 4.days.ago }
      let(:objective_revision) do
        stub('ObjectiveRevision',
             objective: test_objective,
             updated_on: test_updated_on,
            )
      end

      it 'stores revision fields' do
        mapper.store_all [objective_revision]
        revision_record = new_task_record.objective_revisions.first
        revision_record.objective.should  eq(test_objective)
        revision_record.updated_on.should eq(test_updated_on.round)
      end
    end
  end

  describe '#map_to_re' do
    context 'new task record' do
      let(:new_task_record) { Task::Records::Task.create! }
      let(:mapper) { described_class.new new_task_record }

      before(:each) do
        mapper.store objective_revision
      end
    end
  end

end
