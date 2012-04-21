class TaskMapper
  def self.create(attrs = {})
    TaskRecord.new.tap do |task|
      task.body = attrs.fetch(:body)
      current_time = Time.current
      task.created_on = attrs.fetch(:on, current_time)

      task.parent_id = attrs[:project].id if attrs.has_key? :project

      task.user = attrs[:user]

      task.effective_date = [current_time, task.created_on].max
      task.save!
    end
  end

  def self.fetch_all(conditions = {})
    t = TaskRecord.scoped

    if user = conditions[:for_user]
      t = t.where(user_id: user.id)
    end

    t.all
  end

  def self.fetch_by_id(task_id)
    TaskRecord.find(task_id)
  end

  def self.save(task)
    task.save!
  end
end
