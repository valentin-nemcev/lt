module Task
  module PersistenceMethods

    def initialize(attrs={})
      self.id = attrs[:id]
    end

    def persisted?
      !!id
    end

    def id=(id)
      if persisted? && id
        raise InvalidTaskError, "Can't change id of already persisted task"
      end
      fields[:id] = id
      return self
    end

    def id
      fields[:id]
    end

  end
end
