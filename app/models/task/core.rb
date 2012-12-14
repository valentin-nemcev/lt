module Task
  class IncorrectEffectiveDateError < TaskError; end;
  class Core
    attr_reader :effective_date

    def ==(other)
      other && other.respond_to?(:id) && other.id == self.id
    end

    def initialize(attrs={})
      now = attrs.fetch(:clock, Time).current
      @created_on = attrs[:on] || attrs[:created_on] || now
      @effective_date = [created_on, now].max
    end

    attr_reader :created_on

    def effective_date=(date)
      if date < self.created_on
        raise IncorrectEffectiveDateError, "Task didn't exist as of #{date}"
      end
      @effective_date = date
      return self
    end

    def effective_interval
      TimeInterval.beginning_at created_on
    end

    def effective_in?(given_time_interval)
      effective_interval.overlaps_with? given_time_interval
    end


    def id
      object_id
    end

    def destroy
    end

    def inspect
      id_str = id.nil? || id == object_id ? '' : ":#{id}"
      "<#{self.class}:#{sprintf('%016x', object_id)}#{id_str}>"
    end
  end
end
