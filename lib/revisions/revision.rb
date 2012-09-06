module Revisions
  class Revision
    def initialize(opts={})
      @updated_value = opts.fetch :updated_value
    end

    def updated_value
      @updated_value
    end
  end
end
