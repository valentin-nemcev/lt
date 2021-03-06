module Persistable
  class AlreadyPersistedError < StandardError
    def initialize(old_id, new_id)
      @old_id, @new_id = old_id, new_id
    end

    def message
      "Can't persist already persisted object " \
        "(old id was #{@old_id}, new id is #{@new_id})"
    end
  end


  def initialize(attrs={})
    super
    self.id = attrs[:id]
  end

  def persisted?
    !!id
  end

  attr_reader :id

  def id=(id)
    if persisted? && id && self.id != id
      raise AlreadyPersistedError.new self.id, id
    end
    @id = id
    return self
  end
end
