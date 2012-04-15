require 'spec_helper'

describe Task do
  describe 'single task' do
    let(:single_task) { Task.create! }
    subject { single_task }

    it { should be_actionable }

    context 'created' do

      context 'seen from now' do
        it 'should have creation date in past' do
          subject.created_at.should be <= DateTime.now
        end
      end

      context 'seen from past' do
        subject do
          task_created_at = single_task.created_at
          Task.for_date(task_created_at - 1.second).first
        end

        it {should be_nil}
      end
    end


    shared_examples 'not completed' do
      it { should_not be_completed }
      it 'should have no completion date' do
        subject.completed_at.should be_nil
      end
    end

    shared_examples 'completed' do
      it { should be_completed }
      it { should_not be_actionable }
      it 'should have completion date in the past' do
        subject.completed_at.should be <= DateTime.now
      end
    end


    context 'not completed' do
      include_examples 'not completed'
    end

    context 'completed' do
      subject { single_task.complete! }
      include_examples 'completed'
    end

    context 'completed, then completion undone' do
      subject { single_task.complete!.undo_complete! }
      it_should_behave_like 'not completed'
    end

    context 'completed on future date' do
      let(:future_date) { DateTime.now + 1.day }

      context 'seen from now' do
        subject { single_task.complete!(future_date)  }

        it { should_not be_completed }
        it 'should have completion date in the future' do
          subject.completed_at.should == future_date
        end
      end

      context 'seen from future date' do
        subject do
          single_task.complete!(future_date)
          Task.for_date(future_date).first
        end

        it { should be_completed }
      end
    end
  end

  describe 'tasks with subtasks (project)' do
    let :project do
      Task.create!.tap do |project|
        2.times do
          project.subtasks.create!
        end
        project.reload
      end
    end

    subject { project }

    it { should be_project }
    it { should_not be_actionable }
  end



  describe 'unscoped tasks' do
    specify 'should behave like scoped to current date' do
      Task.create!
      with_frozen_time do |now|
        unscoped = Task.scoped.first
          scoped = Task.for_date(now).first
        unscoped.current_date.should == now
          scoped.current_date.should == now

        scoped.should == unscoped
      end
    end
  end

end
