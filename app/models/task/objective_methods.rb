module Task
  module ObjectiveMethods

    def initialize(attrs={})
      super

      fields[:objective_revisions] = []

      if attrs[:objective_revisions]
        attrs[:objective_revisions].each do |r|
          add_objective_revision r
        end
      else
        update_objective attrs[:objective], on: created_on
      end
    end

    def update_objective objective, opts={}
      updated_on = opts.fetch :on, effective_date
      obj_last_updated_on = objective_revisions.map(&:updated_on).max
      if obj_last_updated_on && updated_on < obj_last_updated_on
        raise InvalidTaskError, 'Objective updates should be in chronological order'
      end
      add_objective_revision ObjectiveRevision.new(objective, updated_on)
      return self
    end

    def add_objective_revision revision
      if revision.updated_on < created_on
        raise InvalidTaskError, 'Objective updates should be in chronological order'
      end
      fields[:objective_revisions] << revision
      return self
    end

    def objective_revisions
      fields[:objective_revisions].each
    end

    def effective_objective_revisions
      objective_revisions.select { |r| r.updated_on <= effective_date }
    end

    def objective
      effective_objective_revisions.max_by{ |r| r.updated_on }.objective
    end

  end
end
