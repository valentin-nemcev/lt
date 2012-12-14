module Task
  class TaskError < StandardError;
    def name
      self.class.to_s.demodulize.gsub(/Error$/, '').underscore
    end

    def as_json(*)
      name
    end
  end
end
