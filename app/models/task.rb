# TODO: rename to Tasks
module Task

  #TODO: Better exception names
  class TaskError < StandardError;
    def name
      self.class.to_s.demodulize.gsub(/Error$/, '').underscore
    end

    def as_json(*)
      name
    end
  end
  class TaskSubtypeError < TaskError; end;
  def self.new_subtype(subtype, *args)
    fail TaskSubtypeError, 'Empty task subtype' if subtype.blank?
    subtype = case subtype
    when 'action'  then Action
    when 'project' then Project
    else fail TaskSubtypeError, "Unknown task subtype: #{subtype}"
    end
    subtype.new *args
  end
end
