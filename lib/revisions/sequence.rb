module Revisions
  class Sequence
    def initialize(opts = {})
      @created_on = opts.fetch :created_on
      @revision_class = opts[:revision_class]
      @owner = opts.fetch :owner
      set_revisions opts[:revisions] || []
    end
    attr_reader :created_on, :revision_class, :owner

    include Enumerable
    def each(*args, &block)
      @revisions.each(*args, &block)
    end

    def empty?
      @revisions.empty?
    end


    def last
      @revisions.last
    end

    def set_revisions(revisions)
      clear_revisions
      revisions.sort_by(&:sequence_number).each{ |r| add_revision r }
      return self
    end

    def new_revision(revision_attrs)
      attrs = revision_attrs.merge sequence_number: last_sequence_number + 1
      add_revision revision_class.new(attrs)
    end

    protected

    def last_sequence_number
      @revisions.last.try(:sequence_number) || 0
    end

    def last_updated_on
      @revisions.last.try(:updated_on) || created_on
    end

    def add_revision(revision)
      last_sequence_number < revision.sequence_number or
        raise SequenceNumberError.new last_sequence_number,
                                        revision.sequence_number
      last_updated_on <= revision.updated_on or
        raise DateSequenceError.new last_updated_on, revision.updated_on

      revision.owner = owner
      @revisions << revision
      return revision
    end

    def clear_revisions
      @revisions = []
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
