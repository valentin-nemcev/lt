# TODO: rename to Tasks
module Task

  def self.new_subtype(subtype, *args)
    # TODO: Add check for empty or nonexistent subtype
    subtype = const_get(subtype.to_s.camelize)
    subtype.new *args
  end
end
