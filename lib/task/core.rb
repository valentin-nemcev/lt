module Task
  class Core
    attr_reader :effective_date

    def initialize(attrs={})
      now = attrs.fetch(:clock, Time).current
      @creation_date = attrs[:on] || attrs[:creation_date] || now
    end

    attr_reader :creation_date

    def effective_interval
      TimeInterval.beginning_on creation_date
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
