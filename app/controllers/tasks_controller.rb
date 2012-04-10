class TasksController < ResourceController

  def scope
    current_user.tasks
  end

  def resource_name
    :task
  end

  def complete
    with_resource do |resource|
      resource.complete!
    end
  end

  def undo_complete
    with_resource do |resource|
      resource.undo_complete!
    end
  end

end
