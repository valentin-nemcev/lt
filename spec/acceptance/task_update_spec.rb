require 'spec_helper'

feature 'Task update', :acceptance do
  before(:all) { create_test_user }
  let(:tasks) { tasks = find('[widget=tasks]') }

  scenario 'Updating task objective' do
    visit tasks_page
    task_id = create_task :type => :action, :objective => "Test objective"
    tasks.find("[record=task][record-id='#{task_id}']").tap do |task|
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
  end
end
