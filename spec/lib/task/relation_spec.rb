require 'lib/spec_helper'

require 'time_infinity'
require 'persistable'
require 'graph/edge_nodes'
require 'graph/node_edges'
require 'task'
require 'task/relation'

describe Task::Relation do
  class TaskStub
    def edges
      @edges ||= Graph::NodeEdges.new self
    end
  end

  def create_task
    TaskStub.new.tap do |task|
      task.stub(:completion_date => Time::FOREVER)
    end
  end

  def create_relation(attrs={})
    defaults = {supertask: create_task, subtask: create_task, type: test_type}
    described_class.new defaults.merge(attrs)
  end


  let(:test_type)  { :dependency }
  let(:test_date0) { 7.hours.ago }
  let(:test_date1) { 4.hours.ago }
  let(:test_date2) { 2.hours.ago }
  let(:test_date3) { 1.hour.ago }

  context 'created with sub- and supertasks' do
    let(:supertask) { create_task }
    let(:subtask) { create_task }
    let(:relation) { create_relation supertask: supertask, subtask: subtask }

    it 'should have sub- and supertasks' do
      relation.supertask.should be(supertask)
      relation.subtask.should   be(subtask)
    end
  end
  context 'created without addition date' do
    let(:current_time) { Time.current }
    let(:clock) { stub('Clock', current: current_time) }
    let(:relation) { create_relation clock: clock }

    it 'should have default addition date' do
      relation.addition_date.should eq(current_time)
    end
  end

  context 'created with addition date' do
    let(:addition_date)     { test_date1 }
    let(:relation_on)       { create_relation       on: addition_date }
    let(:relation_addition_date) { create_relation addition_date: addition_date }
    subject(:relation) { relation_on }

    it 'should have passed addition date' do
      relation_on.addition_date.should eq(addition_date)
      relation_addition_date.addition_date.should eq(addition_date)
    end
    its(:removal_date) { should be Time::FOREVER }
    it { should_not be_removed }

    it "couldn't be removed earlier than it was created" do
      expect do
        relation.remove on: test_date0
      end.to raise_error Task::InvalidRelationError
    end
  end

  context 'created with addition and valid removal date' do
    let(:addition_date) { test_date1 }
    let(:removal_date)  { test_date2 }
    subject(:relation) do
      create_relation addition_date: addition_date, removal_date: removal_date
    end

    its(:addition_date)   { should eq(addition_date) }
    its(:removal_date) { should eq(removal_date) }
    it { should be_removed }

    it 'should not allow changing changing removal date' do
      expect do
        relation.remove on: test_date3
      end.to raise_error Task::InvalidRelationError
    end
  end

  context 'when adding subtasks to completed task' do
    let(:supertask) do
      create_task.tap{ |task| task.stub(:completion_date => test_date2) }
    end
    let(:subtask) { create_task }

    it 'raises error if added after completion' do
      expect do
        create_relation \
          :supertask => supertask, :subtask => subtask,
          :addition_date => test_date3,
          :type => :composition
      end.to raise_error Task::InvalidRelationError
    end

    it 'does not raise error if added before completion' do
      expect do
        create_relation \
          :supertask => supertask, :subtask => subtask,
          :addition_date => test_date1,
          :type => :composition
      end.not_to raise_error Task::InvalidRelationError
    end
  end

  context 'when removing subtasks from completed task' do
    let(:supertask) do
      create_task.tap{ |task| task.stub(:completion_date => test_date2) }
    end
    let(:subtask) { create_task }
    let(:relation) do
      create_relation \
        :supertask => supertask, :subtask => subtask,
        :addition_date => test_date0,
        :type => :composition
    end

    it 'raises error if removed after completion' do
      expect do
        relation.remove :on => test_date3
      end.to raise_error Task::InvalidRelationError
    end

    it 'does not raise error if removed before completion' do
      expect do
        relation.remove :on => test_date1
      end.not_to raise_error Task::InvalidRelationError
    end
  end


  describe '#destroy' do
    subject(:relation) { create_relation }
    it 'disconnects relation from its sub- and supertasks' do
      relation.destroy
      relation.subtask.should be_nil
      relation.supertask.should be_nil
    end
  end
end
