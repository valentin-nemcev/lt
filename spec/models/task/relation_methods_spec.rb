require 'lib/spec_helper'

require 'models/task'
require 'models/task/relation_methods'
require 'models/task/relation'

describe 'Task with relations' do
  before(:each) { stub_const('TaskWithRelations', Class.new(Task::Core)) }
  before(:each) do
    TaskWithRelations.instance_eval do
      include Task::RelationMethods
      has_relation :relation_type, supers: :supertasks_name,
        subs: :subtasks_name
      define_method(:inspect) { '<task>' }
    end
  end

  def create_task(name)
    TaskWithRelations.new(created_on: created_on).tap do |task|
      task.define_singleton_method(:inspect) { "<task #{name}>" }
    end
  end

  let(:addition_date) { Time.zone.parse('2012-01-02') }
  let(:created_on)    { Time.zone.parse('2012-01-01') }
  let(:related_task1) { create_task(:related_task1) }
  let(:related_task2) { create_task(:related_task2) }

  subject(:task) { create_task(:subject) }

  its('class.related_tasks') {
    should match_array([:supertasks_name, :subtasks_name])
  }

  let(:some_relation_type) { :composition }
  context 'with existing relations' do
    let!(:relation1) { Task::Relation.new(
      supertask: task, subtask: related_task1, type: some_relation_type ) }
    let!(:relation2) { Task::Relation.new(
      subtask: task, supertask: related_task2, type: some_relation_type) }
    its(:relations) { should match_array [relation1, relation2] }

    describe '#with_connected_tasks_and_relations' do
      it 'returns its connected relation, tasks, and self' do
        tasks, rels = task.with_connected_tasks_and_relations
        tasks.to_a.should match_array [task, related_task1, related_task2]
        rels.to_a.should match_array [relation1, relation2]
      end
    end
  end


  describe '#update_related_tasks' do
    context 'without existing relations' do
      describe 'adding new relations' do
        let(:updates) { { relation_type: {
          supertasks: [related_task1],
          subtasks:   [related_task2]}} }

        let(:updated_relations) do
          task.update_related_tasks updates, on: addition_date
        end
        specify { updated_relations.should have(2).relations }

        let(:relation1) {
          updated_relations.find{ |r| r.supertask == related_task1 } }
        let(:relation2) {
          updated_relations.find{ |r| r.subtask == related_task2 } }

        specify { relation1.subtask.should be task }
        specify { relation2.supertask.should be task }

        specify { relation1.type.should be :relation_type }
        specify { relation2.type.should be :relation_type }

        specify { relation1.added_on.should eq addition_date }
        specify { relation2.added_on.should eq addition_date }
      end
    end

    context 'with exisiting relations' do
      let(:existing_updates) { { relation_type: {
        supertasks: [related_task1],
        subtasks:   [related_task2]
      } } }

      before do
        task.update_related_tasks existing_updates, on: addition_date
      end

      describe 'adding another task' do
        let(:new_related_task) { create_task(:new_related_task) }
        let(:new_addition_date) { addition_date + 1.day }

        let(:updates) { { relation_type: {
          supertasks: [related_task1],
          subtasks:   [related_task2, new_related_task]}} }

        let!(:updated_relations) do
          task.update_related_tasks updates, on: new_addition_date
        end
        specify { task.relations.should have(3).relations }
        specify { updated_relations.should have(1).relation }

        let(:new_relation) { updated_relations.first }

        specify { new_relation.subtask.should be new_related_task }
        specify { new_relation.supertask.should be task }

        specify { new_relation.type.should be :relation_type }

        specify { new_relation.added_on.should eq new_addition_date }
      end

      describe 'removing task' do
        let(:removal_date) { addition_date + 1.day }

        let(:updates) { { relation_type: {
          supertasks: [related_task1],
          subtasks:   []
        } } }

        let!(:updated_relations) do
          task.update_related_tasks updates, on: removal_date
        end
        specify { task.relations.should have(2).relations }
        specify { updated_relations.should have(1).relation }

        let(:removed_relation) { updated_relations.first }

        specify { removed_relation.subtask.should be related_task2 }
        specify { removed_relation.supertask.should be task }

        specify { removed_relation.type.should be :relation_type }

        specify { removed_relation.should be_removed }
      end
    end
  end

  describe '#destroy_relations', :pending
end
