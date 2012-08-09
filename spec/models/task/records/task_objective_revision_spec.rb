require 'spec_helper'

class ObjectiveRevisionDouble
  include Task::PersistenceMethods

  def fields
    @fields ||= {}
  end
end


describe Task::Records::TaskObjectiveRevision do
  let(:revision_records) { described_class }

  let(:test_objective) { 'Test objective' }
  let(:updated_test_objective) { 'Test objective updated' }
  let(:test_updated_on) { 4.days.ago }
  let(:test_sn) { 2 }

  let(:task_record) { Task::Records::Task.create! }

  describe '#save_revisions' do
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
      revision_records.save_revisions task_record, objective_revisions
      expected_size = task_record.objective_revisions.size
      objective_revisions.size.should eq(expected_size)
    end
  end

  describe '#save_revision' do

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

      subject(:revision_record) do
        revision_records.save_revision task_record, objective_revision
      end

      it 'stores revision fields' do
        revision_record.id.should eq(objective_revision.id)
        revision_record.objective.should  eq(test_objective)
        revision_record.updated_on.should eq_up_to_sec(test_updated_on)
      end
    end

    context 'existing revision' do

      before(:each) do
        revision_records.save_revision task_record, objective_revision
        objective_revision.stub( objective: updated_test_objective)
        revision_records.save_revision task_record, objective_revision
      end

      it 'stores updated fields' do
        revision_record = task_record.objective_revisions
          .find(objective_revision.id)
        revision_record.objective.should eq(updated_test_objective)
      end
    end
  end

  describe '#load_revisions' do
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
        revisions = revision_records.load_revisions task_record
        revisions.size.should eq(3)
      end

      it 'fetched revisions in correct order' do
        revisions = revision_records.load_revisions task_record
        revisions.map(&:sequence_number).should eq([1, 2, 3])
      end
    end

    it 'fetches revision fields' do
      revision_record = task_record.objective_revisions.create! do |rec|
        rec.objective = test_objective
        rec.updated_on = test_updated_on
        rec.sequence_number = test_sn
      end

      Task::ObjectiveRevision.should_receive(:new) do |attrs|
        attrs = OpenStruct.new attrs
        attrs.objective.should  eq(test_objective)
        attrs.updated_on.should eq_up_to_sec(test_updated_on)
        attrs.sequence_number.should eq(test_sn)
        attrs.id.should eq(revision_record.id)
      end
      revision_records.load_revisions(task_record).fetch 0
    end
  end
end
