class Project < Task

  def actionable?
    false
  end

  def completed?
    !subtasks.empty? && blocked?
  end
end
