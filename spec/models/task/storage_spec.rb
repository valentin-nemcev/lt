require 'spec_helper'

describe Task::Storage do
  let(:storage) { Task::Storage.new user: user }
  let(:user) { stub('User') }

  let(:task) { stub('task') }
  let(:relation) { stub('relation') }
  let(:graph) { stub('task_graph', tasks: [], relations: []) }

  before(:each) { stub_const('Task::Graph', stub('Task::Graph')) }
  before(:each) { stub_const('Task::Records::Task', stub('Records::Task')) }
  before(:each) do
    Task::Records::Task.should_receive(:for_user).at_most(:once)
      .with(user).and_return(task_base)
  end
  before(:each) { stub_const('Task::Records::Relation', stub('relation_base')) }

  let(:task_base) { stub('task_base') }
  let(:relation_base) { Task::Records::Relation }


  describe '#store' do
    before(:each) do
      Task::Graph.should_receive(:new).with(tasks: [task]).and_return(graph)
    end
    it 'stores task with its graph' do
      storage.store(task).should eq(graph)
    end
  end

  let(:task_id) { 54 }
  let(:relation_id) { 25 }
  describe '#store_graph' do

    it 'maps tasks and relations to records' do
      graph.stub(:tasks => [task], :relations => [relation])

      task_record     = stub('task_record'     , id: task_id)
      relation_record = stub('relation_record' , id: relation_id)

      task_base.should_receive(:save_task).with(task).and_return(task_record)
      relation_base.should_receive(:save_relation)
          .with(relation, {task_id => task_record}).and_return(relation_record)

      task.should_receive(:'id=').with(task_id)
      relation.should_receive(:'id=').with(relation_id)

      storage.store_graph(graph)
    end
  end

  describe 'fetching' do
    let(:task_scope) { stub('task_scope') }
    before(:each) do
      task_scope.stub(:load_tasks => [task])
      task.stub(:id => task_id)

      task_scope.should_receive(:relations)
        .and_return(relation_scope = stub('relation_scope'))
      relation_scope.should_receive(:load_relations)
        .with({task_id => task}).and_return([relation])

      Task::Graph.should_receive(:new)
        .with(tasks: [task], relations: [relation]).and_return(graph)

      graph.stub(tasks: [task])
    end

    describe '#fetch' do
      it 'returns single task' do
        task_base.should_receive(:graph_scope).with(task_id)
          .and_return(task_scope)
        storage.fetch(task_id).should eq(task)
      end
    end

    describe '#fetch_all' do
      it 'fetches graph of all tasks' do
        task_base.should_receive(:all_graph_scope).and_return(task_scope)
        storage.fetch_all.should eq([task])
      end
    end
  end
end
