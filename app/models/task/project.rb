module Task
  class Project < Base

    def type; :project; end

    def actionable?
      false
    end

    def completed?
      !subtasks.empty? && !blocked?
    end

  end
end
