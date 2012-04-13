class TasksController < ResourceController

  def scope
    s = current_user.tasks
    if params[:current_date]
      current_date = Time.parse params[:current_date]
      s = s.for_date current_date
    end
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
