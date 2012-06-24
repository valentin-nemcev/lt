module Task
  class Mapper
    def self.create(attrs = {})
      Record.new.tap do |task|
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
      t = Record.scoped

      if user = conditions[:for_user]
        t = t.where(user_id: user.id)
      end

      t.all
    end

    def self.fetch_by_id(task_id)
      Record.find(task_id)
    end

    def self.save(task)
      task.save!
    end



    def get_new_id
      @last_id ||= 0
      @last_id += 1
    end

    def storage
      @storage ||= {}
    end

    def save(task)
      id = if task.persisted? then task.id else get_new_id end
      storage[id] = task
      task.id = id unless task.persisted?
    end

    def load_all
      storage.values
    end

    def load_by_id id
      storage[id]
    end

  end
end
