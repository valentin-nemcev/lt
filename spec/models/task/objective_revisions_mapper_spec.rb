require 'spec_helper'

describe Task::ObjectiveRevisionsMapper do

  class ObjectiveRevisionDouble
    include Task::PersistenceMethods
    def fields
      @fields ||= {}
    end

  end

  let(:test_objective) { 'Test objective' }
  let(:updated_test_objective) { 'Test objective updated' }
  let(:test_updated_on) { 4.days.ago }

  let(:task_record) { Task::Records::Task.create! }
  let(:mapper) { described_class.new task_record }

  describe '#store_all' do

    let(:objective_revisions) do
      [1..3].map do |i|
        ObjectiveRevisionDouble.new.tap do |rev|
          rev.stub(
            objective: "Test objective #{i}",
            updated_on: test_updated_on,
          )
        end
      end
    end

    it 'stores all revisions' do
      mapper.store_all objective_revisions
      expected_size = task_record.objective_revisions.size
      objective_revisions.size.should eq(expected_size)
    end

    let(:objective_revision) do
      ObjectiveRevisionDouble.new.tap do |rev|
        rev.stub(
          objective: test_objective,
          updated_on: test_updated_on,
        )
      end
    end

    context 'new revision' do

      before(:each) do
        mapper.store_all [objective_revision]
      end

      specify { objective_revision.should be_persisted }

      it 'stores revision fields' do
        revision_record = task_record.objective_revisions
          .find(objective_revision.id)
        revision_record.objective.should  eq(test_objective)
        revision_record.updated_on.should eq_up_to_sec(test_updated_on)
      end
    end

    context 'existing revision' do

      before(:each) do
        mapper.store_all [objective_revision]
        objective_revision.stub( objective: updated_test_objective)
        mapper.store_all [objective_revision]
      end

      it 'stores updateds fields' do
        revision_record = task_record.objective_revisions
          .find(objective_revision.id)
        revision_record.objective.should eq(updated_test_objective)
      end
    end
  end

  describe '#fetch_all' do
    it 'fetched all revisions' do
      revisions = mapper.fetch_all
      expected_size = task_record.objective_revisions.size
      revisions.size.should eq(expected_size)
    end

    # TODO: Add spec for saving sequence numbers
    it 'fetches revision fields' do
      task_record.objective_revisions.create! do |rec|
        rec.objective = test_objective
        rec.updated_on = test_updated_on
      end

      Task::ObjectiveRevision.should_receive(:new) do |attrs|
        attrs = OpenStruct.new attrs
        attrs.objective.should  eq(test_objective)
        attrs.updated_on.should eq_up_to_sec(test_updated_on)
      end
      revision = mapper.fetch_all.fetch 0
    end
  end
end
