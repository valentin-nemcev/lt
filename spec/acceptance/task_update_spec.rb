require 'spec_helper'
require 'acceptance/tasks'

feature 'Task update', :acceptance do
  before(:each) { create_test_user }
  let(:tasks) { tasks = find('[widget=tasks]') }

  scenario 'Updating task objective' do
    visit tasks_page
    task_id = create_task :type => 'action', :objective => "Test objective"
    task = tasks.find("[record=task][record-id='#{task_id}']")

    task.find("[control=select]").click
    task.find("[control=update]").click
    task.find("[form=update-task]").tap do |form|
      form.find("[input=objective]").tap do |objective|
        objective.value.should eq('Test objective')
        objective.set('Test objective updated')
      end
      form.find("[control=save]").click
    end
    task.find('[field=objective]').should have_content('Test objective updated')
    reload_page
    task.find('[field=objective]').should have_content('Test objective updated')
  end

  scenario 'Updating action state' do
    visit tasks_page
    task_id = create_task :type => 'action', :state => 'underway'
    task = tasks.find("[record=task][record-id='#{task_id}']")

    task.find("[control=select]").click
    task.find("[control=update]").click
    task.find("[form=update-task]").tap do |form|
      form.find('[input=state]').tap do |state|
        state.option_set.should eq('underway')
        available_options = %w{considered underway completed canceled}
        # TODO:
        # state.options.should match_array(available_options)
        state.set_option('considered')
      end
      form.find("[control=save]").click
    end
    task.should match_selector('[task-state=considered]')

    reload_page
    task.should match_selector('[task-state=considered]')
  end

  scenario 'Updating project state' do
    visit tasks_page

    task_id = create_task :type => 'project', :state => 'underway'
    task = tasks.find("[record=task][record-id='#{task_id}']")

    task.find("[control=select]").click
    task.find("[control=update]").click
    task.find("[form=update-task]").tap do |form|
      form.find('[input=state]').tap do |state|
        state.option_set.should eq('underway')
        available_options = %w{considered underway canceled}
        # TODO:
        # state.options.should match_array(available_options)
      end
    end
  end

  context 'Project hierarhy', :pause_if_failed do
    before(:each) { visit tasks_page }
    let(:task_widget)    { Acceptance::Task::Widget.new }
    let(:super_project)  { task_widget.new_project \
                            objective: 'Super project', state: 'underway'}
    let(:project)        { super_project.new_sub_project \
                            objective: 'Project', state: 'underway'}
    let!(:action1)       { project.new_sub_action }
    let!(:action2)       { project.new_sub_action }

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
end
