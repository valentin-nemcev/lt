require 'spec_helper'

describe Task::Graph do
  def stub_task(name, methods = {})
    stub(name).tap do |task|
      task.stub(
        methods.merge :with_connected_tasks_and_relations => [[task], []]
      )
    end
  end

  context 'with passed tasks' do
    let(:task)              { stub_task('task') }
    let(:another_task)      { stub_task('task') }
    let(:connected_task)    { stub_task('connected_task') }
    let(:disconnected_task) { stub_task('disconnected_task') }

    let(:relation1) { stub('relation1') }
    let(:relation2) { stub('relation2') }

    context 'without tasks' do
      subject(:graph) { described_class.new tasks: [] }

      its(:tasks) { should be_empty }
      its(:relations) { should be_empty }
      its(:attribute_revisions) { should be_empty }
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
      described_class.new.add_tasks tasks: tasks, relations: relations
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
        described_class.new.add_tasks tasks: tasks, relations: relations
      end.to raise_error Task::Graph::IncompleteGraphError
    end
  end

  context 'with tasks' do
    let(:task1) { stub_task('task1', id:  1 ) }
    let(:task2) { stub_task('task2', id: '2') }

    subject(:graph) do
      described_class.new tasks: [task1, task2]
    end

    describe '#new_task' do
      let(:new_task_args) { :new_task_args }
      let(:new_task) { stub('New task') }
      before do
        new_task.stub(:with_connected_tasks_and_relations => [[new_task], []])
        Task::Base.should_receive(:new).
          with(new_task_args).and_return(new_task)
      end
      it 'creates task, includes it in graph and returns it' do
        graph.new_task(new_task_args).should be new_task

        graph.tasks.should include(new_task)
      end
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
        graph.attribute_revisions.should match_array(
          [:task_rev1, :task_rev2, :another_task_rev1])
      end
    end

    describe '#computed_attributes' do
      let(:args) { %w{some args} }
      it 'returns all tasks computed revisions' do
        task1.stub(:computed_attribute_revisions)
          .with(*args).and_return([:task_crev1, :task_crev2])
        task2.stub(:computed_attribute_revisions)
          .with(*args).and_return([:another_task_crev1])
        graph.computed_revisions(*args).should match_array(
          [:task_crev1, :task_crev2, :another_task_crev1])
      end
    end
  end
end
