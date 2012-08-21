module Revisions
  class Sequence
    def initialize(opts = {})
      @created_on = opts.fetch :created_on
      set_revisions opts[:revisions] || []
    end
    attr_reader :created_on

    include Enumerable
    def each(*args, &block)
      @revisions.each(*args, &block)
    end

    def empty?
      @revisions.empty?
    end


    def last_on(effective_date)
      @revisions.select{ |r| r.updated_on <= effective_date }.last
    end

    def last_sequence_number
      @revisions.last.try(:sequence_number) || 0
    end

    def clear_revisions
      @revisions = []
      return self
    end

    def set_revisions(revisions)
      clear_revisions
      revisions.sort_by(&:sequence_number).each{ |r| add_revision r }
      return self
    end

    def add_revision(revision)
      last_updated_on = @revisions.last.try(:updated_on) || created_on
      last_sn = @revisions.last.try(:sequence_number) || 0
      if last_sn >= revision.sequence_number
        raise SequenceNumberError.new last_sn, revision.sequence_number
      end
      if last_updated_on > revision.updated_on
        raise DateSequenceError.new last_updated_on, revision.updated_on
      end
      @revisions << revision
      return self
    end
  end


  class SequenceError < StandardError; end

  class DateSequenceError < SequenceError
    def initialize(last, current)
      @last, @current = last, current
    end

    def message
      'Revision updates should be in chronological order;'\
        " last: #{@last}, current: #{@current}"
    end
  end

  class SequenceNumberError < SequenceError
    def initialize(last, current)
      @last, @current = last, current
    end

    def message
      'Revision sequence numbers should be in ascending order;'\
        " last: #{@last}, current: #{@current}"
    end
  end
end
