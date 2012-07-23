module AcceptanceHelpers
  def create_task(fields = {})
  end

  def tasks_page
    '/'
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
