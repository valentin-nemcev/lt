require 'spec_helper'

describe Task::Graph do
  context 'with passed tasks' do
    let(:task) { stub('task') }
    let(:connected_task) { stub('connected_task') }
    let(:disconnected_task) { stub('disconnected_task') }

    let(:relation1) { stub('relation1') }
    let(:relation2) { stub('relation2') }

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

      it 'returns all tasks connected to passed tasks' do
        task.should_receive(:with_connected_tasks_and_relations)
          .and_return([[task, connected_task], []])
        connected_task.should_not_receive(:with_connected_tasks_and_relations)
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
    let(:tasks) { %w{task1 task2} }
    let(:relations) { %w{relation1 relation2} }
    subject(:graph) do
      described_class.new_from_records tasks: tasks, relations: relations
    end
    it 'returns passed tasks and relations' do
      graph.tasks.to_a.should match_array(tasks)
      graph.relations.to_a.should match_array(relations)
    end
  end
end
