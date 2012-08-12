require 'spec_helper'

class TaskDouble
  include Task::PersistenceMethods
  def fields
    @fields ||= {}
  end
end

describe Task::Records::Task do

  let(:user_fixture) { User.create! login: 'test_user' }

  let(:task_records) { Task::Records::Task.for_user user_fixture }
  let(:revision_records) { Task::Records::TaskObjectiveRevision }

  let(:task_created_on) { 2.days.ago }
  let(:task) do
    TaskDouble.new.tap do |task|
      task.stub created_on: task_created_on, objective_revisions: [],
        type: 'task_type'
    end
  end
  let(:not_persisted_task) { task.id = nil; task }

  describe '.save_task' do
    before(:each) { revision_records.stub(:save_revisions => []) }
    context 'not persisted task' do
      before(:each) { @task_record = task_records.save_task not_persisted_task }
      attr_reader :task_record
      subject { not_persisted_task }

      it { should be_persisted }
      its(:id) { should eq(task_record.id) }
    end

    context 'persisted task' do
      let(:record_id) { task_records.create!.id }
      let(:persisted_task) { task.id = record_id; task }
      subject(:saved_record) { task_records.save_task persisted_task }

      its(:id) { should eq(record_id) }
    end

  end

  describe '#map_from_task' do
    subject(:task_record) { task_records.new.map_from_task task }

    it { should_not be_nil }
    its(:created_on) { should eq_up_to_sec(task_created_on) }
    its(:user)       { should eq(user_fixture) }
    its(:type)       { should eq('task_type') }

    let(:task_objective_revisions) { [:rev1, :rev2] }
    let(:task_o_rev_records) { [revision_records.new] }

    before(:each) do
      task.stub objective_revisions: task_objective_revisions
      revision_records.should_receive(:save_revisions) do |rec, revs|
        @received_task_record = rec
        revs.should eq(task_objective_revisions)
        task_o_rev_records
      end
    end

    it 'delegates objective revisions saving' do

      task_record.objective_revisions.should eq(task_o_rev_records)
      @received_task_record.should eq(task_record)
    end

  end

  describe '#map_to_task' do
    let(:task_record) do
      task_records.create! created_on: task_created_on, type: 'task_type'
    end
    before(:each) do
      Task.should_receive(:new_subtype) { |type, a|
        OpenStruct.new(a).tap{ |s| s.type = type }
      }
    end
    subject(:task) { task_record.map_to_task }

    its(:id)   { should eq(task_record.id) }
    its(:type) { should eq('task_type') }
    its(:created_on) { should eq_up_to_sec(task_created_on) }

    let(:task_objective_revisions) { [:rev1, :rev2] }

    before(:each) do
      revision_records.should_receive(:load_revisions) do |rec|
        @received_task_record = rec
        task_objective_revisions
      end
    end

    it 'delegates loading objective revisions' do
      task.objective_revisions.should eq(task_objective_revisions)
      @received_task_record.should eq(task_record)
    end
  end

  describe '.destroy_task' do
    let(:record_id) { task_records.create!.id }
    let(:persisted_task) { task.id = record_id; task }

    it 'destroys task record' do
      task_records.destroy_task(persisted_task)
      task_records.find_by_id(record_id).should be_nil
    end
  end
end
