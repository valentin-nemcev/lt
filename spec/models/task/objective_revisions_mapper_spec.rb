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
  let(:test_sn) { 2 }

  let(:task_record) { Task::Records::Task.create! }
  let(:mapper) { described_class.new task_record }

  describe '#store_all' do

    let(:objective_revisions) do
      (1..3).map do |i|
        ObjectiveRevisionDouble.new.tap do |rev|
          rev.stub(
            objective: "Test objective #{i}",
            updated_on: test_updated_on,
            sequence_number: i,
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
          sequence_number: test_sn,
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
    context 'multiple revisions' do
      before(:each) do
        (1..3).to_a.reverse.map do |i|
          task_record.objective_revisions.create!(
            objective: "Test objective #{i}",
            updated_on: test_updated_on,
            sequence_number: i,
          )
        end
      end

      it 'fetched all revisions' do
        revisions = mapper.fetch_all
        revisions.size.should eq(3)
      end

      it 'fetched revisions in correct order' do
        revisions = mapper.fetch_all
        revisions.map(&:sequence_number).should eq([1, 2, 3])
      end
    end

    # TODO: Add spec for saving sequence numbers
    it 'fetches revision fields' do
      task_record.objective_revisions.create! do |rec|
        rec.objective = test_objective
        rec.updated_on = test_updated_on
        rec.sequence_number = test_sn
      end

      Task::ObjectiveRevision.should_receive(:new) do |attrs|
        attrs = OpenStruct.new attrs
        attrs.objective.should  eq(test_objective)
        attrs.updated_on.should eq_up_to_sec(test_updated_on)
        attrs.sequence_number.should eq(test_sn)
        attrs.id.should_not be_nil
      end
      revision = mapper.fetch_all.fetch 0
    end
  end
end
