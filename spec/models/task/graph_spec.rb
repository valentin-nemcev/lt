require 'spec_helper'

describe Task::Graph do
  context 'with passed tasks' do
    let(:task) { stub('task') }
    let(:another_task) { stub('task') }
    let(:connected_task) { stub('connected_task') }
    let(:disconnected_task) { stub('disconnected_task') }

    let(:relation1) { stub('relation1') }
    let(:relation2) { stub('relation2') }

    context 'without tasks' do
      subject(:graph) { described_class.new tasks: [] }

      its(:tasks) { should be_empty }
      its(:relations) { should be_empty }
      its(:revisions) { should be_empty }
    end

    context 'with single task' do
      subject(:graph) do
        described_class.new tasks: [task]
      end

      it 'returns all tasks connected to passed tasks' do
        task.should_receive(:with_connected_tasks_and_relations)
          .and_return([[task, connected_task], []])
        graph.tasks.to_a.should match_array([task, connected_task])
      end
    end

    context 'with multiple connected tasks' do
      subject(:graph) do
        described_class.new tasks: [task, connected_task]
      end

      before(:each) do
        task.should_receive(:with_connected_tasks_and_relations)
          .and_return([[task, connected_task], []])
        connected_task.should_not_receive(:with_connected_tasks_and_relations)
      end

      it 'returns all tasks connected to passed tasks' do
        graph.tasks.to_a.should match_array([task, connected_task])
      end
    end

    context 'with multiple disconnected tasks' do
      subject(:graph) do
        described_class.new tasks: [task, connected_task, disconnected_task]
      end

      it 'returns all tasks connected to passed tasks' do
        task.should_receive(:with_connected_tasks_and_relations)
          .and_return([[task, connected_task], []])
        disconnected_task.should_receive(:with_connected_tasks_and_relations)
          .and_return([[disconnected_task], []])
        graph.tasks.to_a.should match_array([task, connected_task,
                                            disconnected_task])
      end
    end

    context 'with tasks with relations' do
      subject(:graph) do
        described_class.new tasks: [task, connected_task, disconnected_task]
      end

      it 'returns relations connected to passed tasks' do
        task.should_receive(:with_connected_tasks_and_relations)
          .and_return([[task, connected_task], [relation1]])
        disconnected_task.should_receive(:with_connected_tasks_and_relations)
          .and_return([[disconnected_task], [relation2]])

        graph.tasks
        graph.relations.to_a.should match_array([relation1, relation2])
      end
    end
  end

  context 'with passed tasks and relations' do
    let(:tasks) { [stub('task1'), stub('task2')] }
    let(:relations) { [
      stub('relation1', :incomplete? => false),
      stub('relation2', :incomplete? => false)
    ] }
    subject(:graph) do
      described_class.new_from_records tasks: tasks, relations: relations
    end
    it 'returns passed tasks and relations' do
      graph.tasks.to_a.should match_array(tasks)
      graph.relations.to_a.should match_array(relations)
    end
  end

  context 'with passed tasks and incomplete relations' do
    let(:tasks) { [stub('task1'), stub('task2')] }
    let(:relations) { [
      stub('relation1', :incomplete? => false),
      stub('relation2', :incomplete? => true)
    ] }
    it 'raises an error' do
      expect do
        described_class.new_from_records tasks: tasks, relations: relations
      end.to raise_error Task::Graph::IncompleteGraphError
    end
  end

  context 'with tasks' do
    let(:task1) { stub('task1', id: 1) }
    let(:task2) { stub('task2', id: '2') }

    subject(:graph) do
      described_class.new_from_records tasks: [task1, task2]
    end

    describe '#find_task_by_id' do
      it 'should find task by id comparing ids as strings' do
        graph.find_task_by_id('1').should eq(task1)
        graph.find_task_by_id( 2 ).should eq(task2)
      end
    end

    describe '#revisions' do
      it 'returns all tasks revisions' do
        task1.stub(attribute_revisions: [:task_rev1, :task_rev2])
        task2.stub(attribute_revisions: [:another_task_rev1])
        graph.revisions.should match_array(
          [:task_rev1, :task_rev2, :another_task_rev1])
      end
    end
  end
end
