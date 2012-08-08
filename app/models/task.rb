# TODO: rename to Tasks
module Task
  class TaskSubtypeError < StandardError; end;
  def self.new_subtype(subtype, *args)
    fail TaskSubtypeError, 'Empty task subtype' if subtype.blank?
    subtype = const_get(subtype.to_s.camelize)
    subtype.new *args
  rescue NameError
    fail TaskSubtypeError, "Unknown task subtype: #{subtype}"
  end
end
