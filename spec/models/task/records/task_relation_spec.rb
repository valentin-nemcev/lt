require 'spec_helper'

class RelationDouble
  include Persistable

  def initialize(*)
  end
end

describe Task::Records::TaskRelation do

  let(:relation_records) { Task::Records::TaskRelation }
  let(:task_records) { Task::Records::Task }

  let(:relation_removal_date) { 1.day.ago }
  let(:relation_addition_date)   { 2.days.ago }
  let(:relation) do
    RelationDouble.new.tap do |relation|
      relation.stub addition_date: relation_addition_date,
        removal_date: relation_removal_date, type: 'relation_type',
        subtask: task1, supertask: task2,
        removed?: relation_removal_date.present?
    end
  end

  let(:task1_id) { 1 }; let(:task2_id) { 2 }
  let(:task1) { stub('task1', id: task1_id) }
  let(:task2) { stub('task2', id: task2_id) }

  let(:task_record1) { task_records.create! }
  let(:task_record2) { task_records.create! }

  let(:task_records_map) { {task1_id => task_record1, task2_id => task_record2} }
  let(:task_map) { {task_record1.id => task1, task_record2.id => task2} }

  describe '.save_relation' do
    context 'not persisted relation' do
      subject(:not_persisted_relation) { relation.tap{ |r| r.id = nil } }
      before(:each) do
        @relation_record = relation_records.save_relation(
          not_persisted_relation, task_records_map)
      end
      attr_reader :relation_record

      it { should be_persisted }
      its(:id) { should eq(relation_record.id) }
    end

    context 'persisted relation' do
      let(:record_id) { relation_records.create!.id }
      subject(:persisted_relation) { relation.tap{ |r| r.id = record_id } }
      before(:each) { relation_records.save_relation(persisted_relation,
                                                     task_records_map) }

      its(:id) { should eq(record_id) }
    end
  end

  describe '#map_from_relation' do
    subject(:relation_record) do
      relation_records.new.map_from_relation relation, task_records_map
    end

    it { should_not be_nil }
    its(:addition_date)   { should eq_up_to_sec(relation_addition_date) }
    its(:removal_date) { should eq_up_to_sec(relation_removal_date) }
    its(:type)       { should eq('relation_type') }
    its(:subtask)    { should eq(task_record1) }
    its(:supertask)  { should eq(task_record2) }

    context 'not removed relation' do
      before { relation.stub(:removed? => false) }

      its(:removal_date) { should be_nil }
    end
  end

  describe '#map_to_relation' do
    let(:relation_record) do
      relation_records.create! addition_date: relation_addition_date,
        removal_date: relation_removal_date, type: 'relation_type',
        subtask: task_record1, supertask: task_record2
    end

    before(:each) do
      Task::Relation.should_receive(:new) { |a| OpenStruct.new(a) }
    end
    subject(:relation) { relation_record.map_to_relation(task_map) }

    its(:id)         { should eq(relation_record.id) }
    its(:type)       { should eq('relation_type') }
    its(:addition_date)   { should eq_up_to_sec(relation_addition_date) }
    its(:removal_date) { should eq_up_to_sec(relation_removal_date) }
    its(:subtask)    { should eq(task1) }
    its(:supertask)  { should eq(task2) }

    context 'not removed relation' do
      let(:relation_removal_date) { nil }

      it { should_not respond_to(:removal_date) }
    end
  end
end
