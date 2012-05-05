module Task
  module ObjectiveMethods

    def initialize(attrs={})
      super

      @objective_revisions = []
      update_objective attrs[:objective], on: created_on
    end

    def update_objective objective, opts={}
      updated_on = opts.fetch :on, effective_date
      obj_last_updated_on = @objective_revisions.map(&:updated_on).max
      if obj_last_updated_on && updated_on < obj_last_updated_on
        raise InvalidTaskError, 'Objective updates should be in chronological order'
      end
      @objective_revisions << ObjectiveRevision.new(self, objective, updated_on)
      return self
    end

    def objective_revisions
      @objective_revisions.select { |r| r.updated_on <= effective_date }
    end

    def objective
      objective_revisions.max_by{ |r| r.updated_on }.objective
    end

  end
end
