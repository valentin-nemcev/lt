class Task::Project < Task::Task

  def actionable?
    false
  end

  def completed?
    !subtasks.empty? && blocked?
  end
end
