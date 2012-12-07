module Task
  class Project < Base

    def type; :project; end

    def destroy(&related_task_destroyer)
      related(:subtasks).each(&related_task_destroyer)
      super
    end
  end
end
