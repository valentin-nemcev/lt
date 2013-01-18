module Task
  class Attributes::Sequence
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
          raise NextDateSequenceError.new r.next_update_date, Time::FOREVER
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

    def last_next_update_date
      @revisions.last.try(:next_update_date) || creation_date
    end

    def add_revision(revision)
      last_sequence_number < revision.sequence_number or
        raise SequenceNumberError.new last_sequence_number,
                                        revision.sequence_number
      last_update_date <= revision.update_date or
        raise DateSequenceError.new last_update_date, revision.update_date

      empty? || last_next_update_date == revision.update_date or
        raise NextDateSequenceError.new last_next_update_date, revision.update_date

      revision.owner = owner
      @revisions << revision
      return revision
    end

    def clear_revisions
      @revisions.clear
      return self
    end

    class Error < Task::Error; end

    class DateSequenceError < Error
      def initialize(last, current)
        @last, @current = last, current
      end

      def message
        'Revision updates should be in chronological order;'\
          " last: #{@last}, current: #{@current}"
      end
    end

    class NextDateSequenceError < Error
      def initialize(last, current)
        @last, @current = last, current
      end

      def message
        'Previous revision next update date and'\
        ' current revision update date should match'\
          " previous next update: #{@last}, current: #{@current}"
      end
    end

    class SequenceNumberError < Error
      def initialize(last, current)
        @last, @current = last, current
      end

      def message
        'Revision sequence numbers should be in ascending order;'\
          " last: #{@last}, current: #{@current}"
      end
    end
  end
end
