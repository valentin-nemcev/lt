module Task
  class Attributes::Sequence
    %w[
      InvalidUpdateDateError
      InvalidNextUpdateDateError
      InvalidSequenceNumberError
    ].each { |error_name| const_set(error_name, Class.new(Error)) }

    def initialize(opts = {})
      @creation_date = opts.fetch :creation_date
      @revision_class = opts[:revision_class]
      @owner = opts.fetch :owner

      @revisions = []

      set_revisions opts[:revisions] || []
    end
    attr_reader :creation_date, :revision_class, :owner

    include Enumerable
    def each(*args, &block)
      @revisions.each(*args, &block)
    end

    delegate :count, :empty?, :last, :to => :@revisions


    def last_on(given_date)
      last_index = @revisions.rindex{ |rev| rev.update_date <= given_date }
      last_index and @revisions[last_index]
    end

    def last_before(given_date)
      given_date or return nil
      last_index = @revisions.rindex{ |rev| rev.update_date < given_date }
      last_index and @revisions[last_index]
    end

    def all_in_interval(given_interval)
      @revisions.select{ |r| r.update_date.in? given_interval }
    end

    def set_revisions(revisions)
      clear_revisions
      revisions = revisions.sort_by(&:sequence_number)
      revisions.last.try do |r|
        r.next_update_date == Time::FOREVER or
          raise InvalidNextUpdateDateError.new \
            previous_revision: r,
            expected_next_update_date: Time::FOREVER
      end
      revisions.each{ |r| add_revision r }
      return self
    end

    def new_revision(revision_attrs)
      attrs = revision_attrs.merge(
        next_update_date: Time::FOREVER,
        sequence_number: last_sequence_number + 1
      )
      new_revision = revision_class.new(attrs)

      if empty? || new_revision.different_from?(last)
        last.next_update_date = new_revision.update_date unless empty?
        new_revision.previous_revision = last
        add_revision new_revision
      end
    end

    protected

    def last_sequence_number
      @revisions.last.try(:sequence_number) || 0
    end

    def last_update_date
      @revisions.last.try(:update_date) || creation_date
    end

    def add_revision(revision)
      last_sequence_number < revision.sequence_number or
        raise InvalidSequenceNumberError.new \
          previous_sequence_number: last_sequence_number,
          previous_revision: last,
          next_revision: revision
      last_update_date <= revision.update_date or
        raise InvalidUpdateDateError.new \
          previous_update_date: last_update_date,
          previous_revision: last,
          next_revision: revision

      empty? || last.next_update_date == revision.update_date or
        raise InvalidNextUpdateDateError.new \
          previous_revision: last,
          next_revision: revision

      revision.owner = owner
      @revisions << revision
      return revision
    end

    def clear_revisions
      @revisions.clear
      return self
    end
  end
end
