module Task
  module ObjectiveMethods

    def initialize(attrs={})
      super

      fields[:objective_revisions] = []

      if attrs[:objective_revisions]
        set_objective_revisions attrs[:objective_revisions]
      else
        update_objective attrs[:objective], on: created_on
      end
    end

    def set_objective_revisions(o_revs)
      if o_revs.empty?
        raise InvalidTaskError,
          'Objective revisions are empty'
      end
      o_revs.each do |r|
        add_objective_revision r
      end
    end
    protected :set_objective_revisions

    def update_objective objective, opts={}
      updated_on = opts.fetch :on, effective_date
      obj_last_updated_on = objective_revisions.map(&:updated_on).max
      if obj_last_updated_on && updated_on < obj_last_updated_on
        raise InvalidTaskError,
          'Objective updates should be in chronological order'
      end
      add_objective_revision ObjectiveRevision.new(objective, updated_on)
      return self
    end

    def add_objective_revision revision
      unless revision.kind_of? ObjectiveRevision
        raise InvalidTaskError,
          "#{revision.class} given instead of objective revision"
      end

      if fields[:objective_revisions].empty? &&
          revision.updated_on != self.created_on
        raise InvalidTaskError,
          'First objective revision date should be same as task creation date'\
          " (#{revision.updated_on} != #{self.created_on})"
      end

      if revision.updated_on < created_on
        raise InvalidTaskError,
          'Objective updates should be in chronological order'
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
