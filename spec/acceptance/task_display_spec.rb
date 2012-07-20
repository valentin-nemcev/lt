require 'spec_helper'

feature 'Task display', :acceptance do
  scenario 'Displaying multiple tasks' do
    task_ids = [1..3].map do |i|
      create_task :type => :action, :objective => "Test task #{i}"
    end

    visit tasks_path
    tasks = find('[widget=tasks]')
    task_ids.each do |task_id|
      tasks.should have_selector("[record=task][record-id=#{task_id}]")
    end
  end
end
