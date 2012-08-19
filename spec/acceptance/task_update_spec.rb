require 'spec_helper'

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

  scenario 'Updating task state' do
    visit tasks_page
    task_id = create_task :type => 'action', :state => 'underway'
    task = tasks.find("[record=task][record-id='#{task_id}']")

    task.find("[control=select]").click
    task.find("[control=update]").click
    task.find("[form=update-task]").tap do |form|
      form.find('[input=state]').tap do |state|
        state.option_set.should eq('underway')
        available_options = %w{considered underway completed canceled}
        state.options.should match_array(available_options)
        state.set_option('considered')
      end
      form.find("[control=save]").click
    end
    task.should match_selector('[task-state=considered]')

    reload_page
    task.should match_selector('[task-state=considered]')

  end
end
