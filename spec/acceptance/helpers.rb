module AcceptanceHelpers

  def pause_if_failed(example)
    example.exception.try do |e|
      puts e
      pause
    end
  end

  def create_task(fields = {})
    fields = {
      type: 'action',
      objective: 'Test task'
    }.merge fields

    visit_unless_current tasks_page

    tasks = find('[widget=tasks]')

    tasks.find('[control=new]').click
    task = tasks.find('[record=task][record-state=new]')
    task.find('[form=new-task]').tap do |form|
      form.find('[input=type]').set(fields[:type])
      form.find('[input=objective]').set(fields[:objective])
      form.find('[control=save]').click
    end
    task.should match_selector('[record-state!=new][record-id]')
    task['record-id']
  end

  def tasks_page
    '/'
  end

  def visit_unless_current(path)
    visit(path) unless current_path == path
  end

  def reload_page
    visit current_path
  end

  def pause
    print "Tests paused, press something to continue"
    STDIN.getc
  end


  def create_test_user
    User.create login: 'test', name: 'Test user'
  end

end
