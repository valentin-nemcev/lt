require 'spec_helper'

describe Task::Mapper do
  let(:task_records) { Task::Records::Task.all }
  let(:user_fixture) { User.create }

  subject(:mapper) { described_class.new user: user_fixture }

  let(:task) do
    double('Task')
  end

  it 'stores single task' do
    mapper.store task
    task_records.should have(1).task_record
  end
end
