require 'spec_helper'

feature 'Task display', :acceptance do
  before(:each) { create_test_user }

  before(:each) do
    visit tasks_page
    @task_ids = (1..3).map do |i|
      create_task :type => :action, :objective => "Test task #{i}"
    end
  end

  let(:tasks) { find('[widget=tasks]') }

  scenario 'Displaying multiple tasks' do
    @task_ids.each do |task_id|
      tasks.should have_selector("[record=task][record-id='#{task_id}']")
    end
  end

  scenario 'Selecting tasks' do
    tasks.should_not have_selector(".selected[record=task]")
    task = tasks.find("[record=task][record-id='#{@task_ids[1]}'] > .task")
    task.find("[control=select]").click
    task.should match_selector('.selected')
    task.should have_selector('.additional-controls')
  end
end
