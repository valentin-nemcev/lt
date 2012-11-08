require 'spec_helper'
require 'acceptance/tasks'

describe 'Task management', :acceptance do
  before(:each) { create_test_user }
  let(:tasks)         { Acceptance::Task::Widget.new }

  describe 'Task deletion' do
    let(:project)  { tasks.new_project }
    let!(:action1) { project.new_sub_action }
    let!(:action2) { project.new_sub_action }

    let(:another_project)  { tasks.new_project }

    context 'when project is deleted' do 
      before { project.delete }
      specify 'its subtasks are deleted too' do
        project.should_not exist
        action1.should_not exist
        action2.should_not exist

        another_project.should exist
      end
    end
  end
end

