require 'spec_helper'

describe Task::Relation do
  class TaskStub
    def edges
      @edges ||= Graph::NodeEdges.new self
    end
  end

  def create_task
    TaskStub.new
  end

  def create_relation(attrs={})
    defaults = {supertask: create_task, subtask: create_task, type: test_type}
    described_class.new defaults.merge(attrs)
  end


  let(:test_type)  { :dependency }
  let(:test_date0) { 7.hours.ago }
  let(:test_date1) { 4.hours.ago }
  let(:test_date2) { 2.hours.ago }

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
      relation.added_on.should eq(current_time)
    end
  end

  context 'created with addition date' do
    let(:addition_date)     { test_date1 }
    let(:relation_on)       { create_relation       on: addition_date }
    let(:relation_added_on) { create_relation added_on: addition_date }
    subject(:relation) { relation_on }

    it 'should have passed addition date' do
      relation_on.added_on.should eq(addition_date)
      relation_added_on.added_on.should eq(addition_date)
    end
    its(:removed_on) { should be_nil }

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
      create_relation added_on: addition_date, removed_on: removal_date
    end

    its(:added_on)   { should eq(addition_date) }
    its(:removed_on) { should eq(removal_date) }

    it 'should allow "unremoving" by setting removal date to nil' do
      relation.remove on: nil
      relation.removed_on.should be_nil
    end
  end

  context 'incomplete' do
    subject(:relation) { create_relation supertask: nil }
    it { should be_incomplete }
  end


  describe '#destroy' do
    subject(:relation) { create_relation }
    it 'disconnects relation from its sub- and supertasks' do
      relation.destroy
      relation.subtask.should be_nil
      relation.supertask.should be_nil
    end
  end

  # TODO: Spec loop check
end
