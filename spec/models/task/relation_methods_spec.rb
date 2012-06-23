require 'spec_helper'

describe Task::RelationMethods do
  class TaskWithRelationMethods < Task::Core
    include Task::RelationMethods
  end

  def create_task(attrs={})
    attrs.reverse_merge! objective: 'Test!'
    TaskWithRelationMethods.new attrs
  end

  context 'with related tasks' do

    [:project1, :project2, :dependent1, :dependent2,
      :blocking1, :blocking2, :component1, :component2
    ].each do |t|
      let(t) { create_task objective: t }
    end

    let(:with_related_on_creation) do
      create_task projects: [project1], dependent_tasks: [dependent1],
        blocking_tasks: [blocking1], component_tasks: [component1]
    end

    shared_examples 'related task collectons on creation' do
      it "has related tasks collections" do
        {
          supertasks:      [project1, dependent1],
          dependent_tasks: [dependent1],
          projects:        [project1],
          subtasks:        [blocking1, component1],
          blocking_tasks:  [blocking1],
          component_tasks: [component1],
        }.each do |collection, contents|
          subject.public_send(collection).to_a.should =~ contents
        end
      end
    end

    shared_examples 'related task collectons after creation' do
      it "has related tasks collections" do
        {
          supertasks:      [project1, project2, dependent1, dependent2],
          dependent_tasks: [dependent1, dependent2],
          projects:        [project1, project2],
          subtasks:        [blocking1, blocking2, component1, component2],
          blocking_tasks:  [blocking1, blocking2],
          component_tasks: [component1, component2],
        }.each do |collection, contents|
          subject.public_send(collection).to_a.should =~ contents
        end
      end
    end

    context 'added on creation' do
      subject { with_related_on_creation }

      it 'has #relations' do
        subject.relations.should have(4).relations
      end

      include_examples 'related task collectons on creation'
    end

    let(:addition_date) { 1.day.from_now }

    let(:with_related_after_creation) do
      opts = {on: addition_date}
      with_related_on_creation.tap do |t|
        t.add_project        project2,   opts
        t.add_dependent_task dependent2, opts
        t.add_blocking_task  blocking2,  opts
        t.add_component_task component2, opts
      end
    end


    context 'added after creation on future date' do
      context 'seen from creation date' do
        subject { with_related_after_creation }

        it 'has #relations' do
          subject.relations.should have(8).relations
        end

        include_examples 'related task collectons on creation'
      end

      context 'seen from addition date' do
        subject { with_related_after_creation.as_of addition_date }

        it 'has #relations' do
          subject.relations.should have(8).relations
        end

        include_examples 'related task collectons after creation'
      end

    end

    let(:removal_date) { 2.day.from_now }

    let(:with_unrelated_after_creation) do
      opts = {on: removal_date}
      with_related_after_creation.tap do |t|
        t.remove_project        project2,   opts
        t.remove_dependent_task dependent2, opts
        t.remove_blocking_task  blocking2,  opts
        t.remove_component_task component2, opts
      end
    end

    context 'removed after addition on future date' do
      context 'seen from addition date' do
        subject { with_unrelated_after_creation.as_of addition_date }

        it 'has #relations' do
          subject.relations.should have(8).relations
        end

        include_examples 'related task collectons after creation'
      end

      context 'seen from removal date' do
        subject { with_unrelated_after_creation.as_of removal_date }

        it 'has #relations' do
          subject.relations.should have(8).relations
        end

        include_examples 'related task collectons on creation'
      end
    end
  end

end
