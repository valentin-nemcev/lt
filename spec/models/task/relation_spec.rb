require 'spec_helper'

describe Task::Relation do
  class TaskStub
    include Graph::Node
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
    let(:relation_on)       { create_relation       on: test_date1 }
    let(:relation_added_on) { create_relation added_on: test_date1 }

    it 'should have passed addition date' do
      relation_on.added_on.should eq(test_date1)
      relation_added_on.added_on.should eq(test_date1)
    end

    it "couldn't be removed earlier than it was created" do
      expect do
        relation_on.remove on: test_date0
      end.to raise_error Task::InvalidRelationError
    end
  end

  context 'created with addition and valid removal date' do
    let(:relation) do
      create_relation added_on: test_date1, removed_on: test_date2
    end

    it 'should have addition and removal dates' do
      relation.added_on.should   eq(test_date1)
      relation.removed_on.should eq(test_date2)
    end

    it 'should allow "unremoving" by setting removal date to nil' do
      relation.remove on: nil
      relation.removed_on.should be_nil
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

  # TODO: Spec loop check
end
