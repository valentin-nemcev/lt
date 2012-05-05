module Task
  class Project < Base

    def actionable?
      false
    end

    def completed?
      !subtasks.empty? && blocked?
    end

  end
end
