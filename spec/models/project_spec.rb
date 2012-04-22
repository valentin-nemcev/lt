require 'spec_helper'

describe Project, :pending do
  def create_action(attrs={})
    Action.new attrs
  end

  def create_project(attrs={})
    Project.new attrs
  end

  let :project do
    create_project.tap { |project|
      2.times { create_task project: project }
    }
  end

  subject { project }

  it { should_not be_actionable }
  it { should_not be_completed }

  it 'could not be completed directly' do
    expect { project.complete! }.to raise_error
  end

  context 'with some subtasks completed' do
    subject { project.subtasks.first.complete!; project }
    it { should_not be_completed }
  end

  context 'with all subtasks completed' do
    let(:with_subtasks_completed) do
      project.tap { |p| p.subtasks.each(&:complete!) }
    end

    context 'and no blocking tasks' do
      subject { with_subtasks_completed }
      it { should be_completed }
      it { should_not be_blocked }
    end

    context 'and with blocking tasks' do
      subject do
        with_subtasks_completed.tap { |p| p.blocking_tasks.create! }
      end

      it { should_not be_completed }
      it { should be_blocked }
    end

    context 'and with completed blocking tasks' do
      subject do
        with_subtasks_completed.tap { |p| p.blocking_tasks.create!.complete! }
      end

      it { should be_completed }
      it { should_not be_blocked }
    end

  end

  context 'with subprojects with subtasks completed' do
    subject do
      create_project.tap { |project|
        2.times {
          project.subtasks.create!.tap { |subproject|
            2.times { subproject.subtasks.create!.complete! }
          }
        }
        project.subtasks.create!.complete!
      }.reload
    end

    it { should be_completed }
  end
end
