require 'spec_helper'

feature "Task creation", :acceptance do
  scenario 'Creating an action' do
    visit tasks_path
    tasks = find('[widget=tasks]')

    tasks.find('[control=new]').click
    tasks.find('[form=new-task]').tap do |form|
      form.find('[input=type]').set('action')
      form.find('[input=objective]').set('Test objective')
      form.find('[control=save]').click
    end

    task = tasks.find('.created[record=task]')
    task_id = task['record-id']
    task_id.should_not be_nil

    task.tap do |task|
      task.find('[field=objective]').should have_content('Test objective')
    end

    reload_page
    tasks.should have_selector("[record=task][record-id=#{task_id}]")
  end

  scenario 'Creating task without objective', :pending
end
