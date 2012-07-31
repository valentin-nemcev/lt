require 'spec_helper'


describe Task::Mapper do
  let(:task_records)    { Task::Records::Task }
  let(:action_records)  { Task::Records::Action }
  let(:project_records) { Task::Records::Project }

  let(:user_fixture) { User.create! login: 'test_user' }
  let(:another_user_fixture) { User.create! login: 'another_test_user' }

  let(:mapper) { described_class.new user: user_fixture }
  let(:mapper_for_another_user) { described_class.new user: another_user_fixture }

  class TaskDouble
    attr_accessor :id
  end

  let(:task_created_on) { 2.days.ago }
  let(:task) do
    TaskDouble.new.tap do |task|
      task.stub created_on: task_created_on, objective_revisions: []
    end
  end

  let(:non_existent_task_id) { 666 }

  def create_task_record
    task_records.create! created_on: task_created_on, user_id: user_fixture.id
  end

  describe '#fetch' do

    it 'instantiates and returns correct task type' do
      {
        action_records => Task::Action,
        project_records => Task::Project
      }.each_pair do |records, factory|
        record = records.create! created_on: task_created_on,
          user: user_fixture
        returned_task = double('Task')
        factory.should_receive(:new).and_return(returned_task)
        mapper.fetch(record.id).should eq(returned_task)
      end
    end

    it 'fetches tasks for correct user' do
      Task::Action.should_receive(:new).and_return(double('Action'))
      record = action_records.create! created_on: task_created_on,
        user: user_fixture
      another_record = action_records.create! created_on: task_created_on,
        user: another_user_fixture

      expect{ mapper.fetch(record.id)         }.to_not raise_error
      expect{ mapper.fetch(another_record.id) }.to raise_error
    end

    describe 'task fields' do
      before(:each) do
        record = action_records.create! created_on: task_created_on,
          user: user_fixture
        Task::Action.should_receive(:new) { |a| @task_attrs = OpenStruct.new a }
        mapper.fetch record.id
      end
      attr_accessor :task_attrs


      it 'stores task creation date' do
        task_attrs.created_on.should eq_up_to_sec(task_created_on)
      end
    end

    it 'raises error when task record in not found' do
      expect {
        mapper.fetch(non_existent_task_id)
      }.to raise_error Task::Mapper::TaskNotFoundError
    end
  end

  describe '#fetch_all' do
    it 'fetches tasks for correct user' do
      Task::Action.should_receive(:new).and_return(double('Action'))
      record = action_records.create! created_on: task_created_on,
        user: user_fixture

      mapper.fetch_all.should have(1).task
      mapper_for_another_user.fetch_all.should have(0).task
    end
  end

  describe '#store' do

    describe 'task fields' do
      before(:each) do
        mapper.store task
        @task_record = task_records.find(task.id)
      end
      subject(:task_record) { @task_record }

      it { should_not be_nil }
      its(:created_on) { should eq_up_to_sec(task_created_on) }
      its(:user)       { should eq(user_fixture) }
    end

    let(:task_objective_revisions) { [:rev1, :rev2] }
    let(:o_revs_mapper) { double('ObjectiveRevisionsMapper') }

    it 'delegates storing objective revisions to another mapper' do
      Task::ObjectiveRevisionsMapper.should_receive(:new) do |task_record|
        @received_task_record = task_record
        o_revs_mapper
      end
      o_revs_mapper.should_receive(:store_all).with(task_objective_revisions)

      task.stub objective_revisions: task_objective_revisions

      mapper.store task
      @received_task_record.should eq(task_records.find(task.id))
    end
  end

  describe '#destroy' do
    before(:each) do
      mapper.store task
      @task_id = task.id
      mapper.destroy task
    end
    attr_accessor :task_id

    it 'destroys task record' do
      task_records.find_by_id(task_id).should be_nil
    end

    it 'removes task id' do
      task.id.should be_nil
    end

    it 'raises error when task record in not found' do
      task.id = non_existent_task_id
      expect {
        mapper.destroy(task)
      }.to raise_error Task::Mapper::TaskNotFoundError
    end

    it 'raises error when task record is not persisted' do
      task.id = nil
      expect {
        mapper.destroy(task)
      }.to raise_error Task::Mapper::TaskMapperError
    end
  end
end
