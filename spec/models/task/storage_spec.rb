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
  before(:each) { stub_const('Task::Records::TaskRelation', stub('relation_base')) }

  let(:task_base) { stub('task_base') }
  let(:relation_base) { Task::Records::TaskRelation }


  describe '#store' do
    before(:each) do
      Task::Graph.should_receive(:new).with(tasks: [task]).and_return(graph)
    end
    it 'stores task with its graph' do
      storage.store(task).should eq(graph)
    end
  end

  let(:task_id) { 54 }
  let(:non_existend_task_id) { 666 }
  let(:relation_id) { 25 }
  describe '#store_graph' do
    let(:task_record    ) { stub('task_record'     , id: task_id    ) }
    let(:relation_record) { stub('relation_record' , id: relation_id) }

    before(:each) do
      task_base.should_receive(:save_task).with(task).and_return(task_record)
    end

    it 'maps tasks and relations to records' do
      graph.stub(:tasks => [task], :relations => [relation])

      relation_base.should_receive(:save_relation)
          .with(relation, {task_id => task_record}).and_return(relation_record)

      storage.store_graph(graph)
    end

    it 'raises error on incomplete graphs' do
      graph.stub(:tasks => [task, nil], :relations => [relation])

      expect {
        storage.store_graph(graph)
      }.to raise_error Task::Storage::IncompleteGraphError
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

      Task::Graph.should_receive(:new_from_records)
        .with(tasks: [task], relations: [relation]).and_return(graph)

      graph.stub(tasks: [task])
    end

    describe '#fetch' do
      it 'returns single task' do
        task_base.should_receive(:graph_scope).with(task_id)
          .and_return(task_scope)
        graph.should_receive(:find_task_by_id).with(task_id).and_return(task)
        storage.fetch(task_id).should eq(task)
      end

      it 'raises error when fetching non-existent task' do
        task_base.should_receive(:graph_scope)
          .with(non_existend_task_id).and_return(task_scope)
        graph.should_receive(:find_task_by_id)
          .with(non_existend_task_id).and_return(nil)

        expect do
          storage.fetch(non_existend_task_id)
        end.to raise_error Task::Storage::TaskNotFoundError
      end
    end

    describe '#fetch_all' do
      it 'fetches graph of all tasks' do
        task_base.should_receive(:all_graph_scope).and_return(task_scope)
        storage.fetch_all.should eq([task])
      end
    end
  end

  describe '#destroy_task' do
    before(:each) do
      task.stub(:id => task_id)
    end

    it 'destroys single task and its relations' do
      task_base.should_receive(:destroy_task).with(task)
      task.should_receive(:destroy_relations)
      task.should_receive(:freeze)
      storage.destroy_task(task).should be_nil
    end
  end
end
