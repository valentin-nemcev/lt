require 'lib/spec_helper'

require 'time_infinity'
require 'time_interval'
require 'persistable'
require 'task'
require 'graph/edge_nodes'
require 'graph/node_edges'
require 'task/relations'
require 'task/relation'

describe Task::Relations do
  before(:each) do
    stub_const('TaskWithRelations', Class.new)
    TaskWithRelations.instance_eval do
      define_method(:edges) { @edges ||= Task::Relations.new(self) }
    end
  end

  def create_task(name)
    TaskWithRelations.new.tap do |task|
      task.define_singleton_method(:inspect) { "<task #{name}>" }
    end
  end
  let(:task0) { create_task(:task0) }
  let(:task1) { create_task(:task1) }
  let(:task2) { create_task(:task2) }
  let(:task3) { create_task(:task3) }
  let(:some_relation_type) { :dependency }
  let(:some_other_relation_type) { :composition }

  let(:date1) { Time.zone.parse('2012.01.01') }
  let(:date2) { Time.zone.parse('2012.01.02') }
  let(:date3) { Time.zone.parse('2012.01.03') }

  describe 'check for duplicate relations' do
    def create_first_relation attrs = {}
      Task::Relation.new({
        type: some_relation_type,
        supertask: task1, subtask: task2,
        addition_date: date1, removal_date: date3}.merge(attrs))
    end

    def create_other_relation
      Task::Relation.new({
        type: some_relation_type,
        supertask: task1, subtask: task0,
        addition_date: date1})
    end

    def create_second_relation attrs = {}
      Task::Relation.new({
        type: some_relation_type,
        supertask: task1, subtask: task2,
        addition_date: date2}.merge(attrs))
    end
    alias_method :create_first_relation_duplicate, :create_second_relation

    it 'raises error for relation with same type and tasks' do
      first = create_first_relation
      create_other_relation
      expect { create_first_relation_duplicate }.to raise_error { |error|
        error.should be_an_instance_of Task::Relations::DuplicateRelationError
        error.should be_a Task::Error
        error.existing.should be first
        error.duplicate.should be
      }
    end

    it "doesn't raise error for non-ovelapping relations" do
      create_first_relation addition_date: date1, removal_date: date2
      create_second_relation addition_date: date2
    end

    it "doesn't raise error for relations with different type" do
      create_first_relation type: some_relation_type
      create_second_relation type: some_other_relation_type
    end

    it "doesn't raise error for relations with different tasks" do
      create_first_relation supertask: task1, subtask: task2
      create_second_relation supertask: task1, subtask: task3
    end
  end

  describe 'check for loops' do
    it 'raises error for relation that creates loop with single task' do
      expect do
        Task::Relation.new(
          type: some_relation_type,
          supertask: task1, subtask: task1,
          addition_date: date1, removal_date: date3)
      end.to(raise_error do |error|
        error.should be_a Task::Error
        error.should be_an_instance_of Task::Relations::RelationLoopError
      end)
    end

    it 'raises error for relation that creates loop' do
      Task::Relation.new(
        type: some_relation_type,
        supertask: task1, subtask: task2,
        addition_date: date1, removal_date: date3)

      Task::Relation.new(
        type: some_relation_type,
        supertask: task2, subtask: task3,
        addition_date: date1, removal_date: date3)

      expect do
        Task::Relation.new(
          type: some_relation_type,
          supertask: task3, subtask: task1,
          addition_date: date1, removal_date: date3)
      end.to(raise_error do |error|
        error.should be_a Task::Error
        error.should be_an_instance_of Task::Relations::RelationLoopError
      end)
    end

    it "doesn't raise error for relation that do not create loop" do
      Task::Relation.new(
        type: some_relation_type,
        supertask: task1, subtask: task2,
        addition_date: date1, removal_date: date2)

      Task::Relation.new(
        type: some_relation_type,
        supertask: task2, subtask: task3,
        addition_date: date1, removal_date: date3)

      Task::Relation.new(
        type: some_relation_type,
        supertask: task3, subtask: task1,
        addition_date: date2, removal_date: date3)
    end
  end
end
