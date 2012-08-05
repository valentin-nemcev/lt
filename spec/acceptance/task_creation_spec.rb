require 'spec_helper'

feature "Task creation", :acceptance do
  before(:each) { create_test_user; visit tasks_page }

  let(:tasks) { find('[widget=tasks]') }

  scenario 'Creating an action' do
    tasks.find('[control=new]').click
    task = tasks.find('[record=task][record-state=new]')
    task.find('[form=new-task]').tap do |form|
      form.find('[input=type][value=action]').set(true)
      form.find('[input=objective]').set('Test objective')
      form.find('[control=save]').click
    end

    task.should match_selector('[record-state!=new]')
    task.should match_selector('[task-type=action]')
    task_id = task['record-id']
    task_id.should_not be_nil

    task.tap do |task|
      task.find('[field=objective]').should have_content('Test objective')
    end

    reload_page
    tasks.should have_selector("[record=task][record-id='#{task_id}']")
  end

  scenario 'Creating a project' do
    tasks.find('[control=new]').click
    task = tasks.find('[record=task][record-state=new]')
    task.find('[form=new-task]').tap do |form|
      form.find('[input=type][value=project]').set(true)
      form.find('[input=objective]').set('Test project objective')
      form.find('[control=save]').click
    end

    task.should match_selector('[task-type=project]')
    task_id = task['record-id']

    reload_page
    task = find("[record=task][record-id='#{task_id}']")
    task.should match_selector('[task-type=project]')
  end

  scenario 'Creating a project subtask' do
    project_id = create_task type: 'project'
    tasks.find("[record=task][record-id='#{project_id}']").tap do |project|
      project.find('[control=select]').click
      project.find('[control=new-subtask]').click
      project.find('[records=subtasks]').tap do |subtasks|
        subtask = subtasks.find('[record=task][record-state=new]')
        subtask.find('[form=new-task]').tap do |form|
          form.find('[input=objective]').set('Test subtask objective')
          form.find('[control=save]').click
        end
        subtask_id = subtask['record-id']
      end
    end
    reload_page
    project = find("[record=task][record-id='#{project_id}']")
    subtasks = project.find('[records=subtasks]')
    subtasks.should have_selector("[record=task][record-id='#{subtask_id}']")
  end

  # TODO: scenario 'Creating task without objective', :pending
end
