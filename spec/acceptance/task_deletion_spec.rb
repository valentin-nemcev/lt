require 'spec_helper'

feature 'Task deletion', :acceptance do
  before(:all) { create_test_user }

  scenario 'Deleting single task' do
    task_id = create_task :type => :action, :objective => 'Test task'
    task_selector = "[record=task][record-id='#{task_id}']"

    visit tasks_page
    tasks = find('[widget=tasks]')
    tasks.find(task_selector).tap do |task|
      task.find('.destructive[control=delete]').click
      task.should match_selector('.deleted')
    end

    reload_page
    tasks.should_not have_selector(task_selector)
  end
end
