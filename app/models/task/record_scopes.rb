module Task
  module RecordScopes
    def generic_effective_in(beginning_col, ending_col, interval)
      return where("0 AND 'interval is empty'") if interval.empty?

      int_beginning, int_ending = *interval.endpoints
      s = scoped
      if int_ending != Time::FOREVER
        # Beginning column is never null
        s = s.where("#{beginning_col} < :int_ending",
                    :int_ending => int_ending)
      end
      if int_beginning != Time::NEVER
        s = s.where("#{ending_col} > :int_beginning OR #{ending_col} IS NULL",
                    :int_beginning => int_beginning)
      end
      s
    end

    def generic_effective_on(beginning, ending, date)
      where(
        "#{beginning} <= :date AND (:date < #{ending} OR #{ending} IS NULL)",
        :date => date
      )
    end
  end
end
