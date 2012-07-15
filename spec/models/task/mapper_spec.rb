require 'spec_helper'

describe Task::Mapper do
  def task_records
    Task::Records::Task
  end

  let(:user_fixture) { User.create! login: 'test_user' }

  subject(:mapper) { described_class.new user: user_fixture }

  class TaskDouble
    attr_accessor :id
  end

  let(:task_created_on) { 2.days.ago }
  let(:task) do
    TaskDouble.new.tap do |task|
      task.stub created_on: task_created_on, objective_revisions: []
    end
  end

  describe '#store' do

    describe 'task fields' do
      before(:each) do
        mapper.store task
        @task_record = task_records.find(task.id)
      end

      it 'sets stored task id' do
        task.id.should_not be_nil
      end

      it 'creates task record' do
        @task_record.should_not be_nil
      end

      it 'stores task creation date' do
        @task_record.created_on.should eq(task_created_on.round)
      end

      it 'set user for record' do
        @task_record.user.should eq(user_fixture)
      end
    end

    let(:task_objective_revisions) { [:rev1, :rev2] }
    it 'delegates storing objective revisions to another mapper' do
      task.stub objective_revisions: task_objective_revisions
      mapper.should_receive(:create_objective_revisions_mapper) do |task_record|
        @task_record = task_record
        double('ObjectiveRevisionsMapper').tap do |o_revs_mapper|
          o_revs_mapper.should_receive(:store_all)
            .with(task_objective_revisions)
        end
      end
      mapper.store task
      @task_record.should eq(task_records.find(task.id))
    end

  end

end
