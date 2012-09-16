module Revisions
  class Revision
    def initialize(opts={})
      @updated_value = opts.fetch :updated_value
      @updated_on = opts.fetch :updated_on
      @owner = opts[:owner]
    end

    attr_reader :owner, :updated_on, :updated_value

    def owner=(new_owner)
      owner.nil? or fail RevisionError.new owner, new_owner
      @owner = new_owner
    end
  end

  class RevisionError < StandardError
    def initialize(last, current)
      @last, @current = last, current
    end

    def message
      "Can't change revision owner"\
        " last: #{@last}, current: #{@current}"
    end
  end

end
