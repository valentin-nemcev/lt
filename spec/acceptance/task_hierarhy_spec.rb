require 'spec_helper'
require 'acceptance/tasks'

describe 'Task hierarhy', :acceptance do
  before(:each) { create_test_user }

  let(:tasks)         { Acceptance::Task::Widget.new }
  let(:super_project) { tasks.new_project \
                         objective: 'Super project', state: 'underway'}
  let(:project)       { super_project.new_sub_project \
                         objective: 'Project', state: 'underway'}
  let!(:action1)      { project.new_sub_action }
  let!(:action2)      { project.new_sub_action }

  describe 'Half-completed project' do
    before(:each) { action1.update_state 'completed' }

    %w{underway considered}.each do |state|
      example "with second action #{state}" do
        action2.update_state 'underway'

        project.should have_state('underway')
        super_project.should have_state('underway')
      end
    end
  end

  describe 'Completed project' do
    before(:each) { action1.update_state 'completed' }

    %w{completed canceled}.each do |state|
      example "with second action #{state}" do
        action2.update_state 'underway'

        project.should have_state('completed')
        super_project.should have_state('completed')
      end
    end
  end
end
