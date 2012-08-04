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

    def objective_revisions
      fields[:objective_revisions].each
    end

    def objective
      effective_objective_revision.objective
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

    def last_sequence_number
      last_objective_revision.try(:sequence_number) || 0
    end

    def last_updated_on
      last_objective_revision.try(:updated_on)
    end

    def last_objective_revision
      fields[:objective_revisions].last
    end

    def update_objective objective, opts={}
      updated_on = opts.fetch :on, effective_date
      last_sequence_number = last_objective_revision.try(:sequence_number) || 0
      attrs = {
        objective: objective,
        updated_on: updated_on,
        sequence_number: last_sequence_number + 1,
      }
      add_objective_revision ObjectiveRevision.new(attrs)
      return self
    end

    protected

    def add_objective_revision revision
      if fields[:objective_revisions].empty? &&
          revision.updated_on != self.created_on
        raise InvalidTaskError,
          'First objective revision date should be same as task creation date'\
          " (#{revision.updated_on} != #{self.created_on})"
      end

      if last_updated_on.try :>, revision.updated_on
        raise InvalidTaskError,
          'Objective updates should be in chronological order'
      end

      if last_sequence_number >= revision.sequence_number
        raise InvalidTaskError,
          'Objective sequence_number should be in ascending order'
      end

      if revision.updated_on < created_on
        raise InvalidTaskError,
          'Objective updates should be in chronological order'
      end
      fields[:objective_revisions] << revision
      return self
    end

    def effective_objective_revision
      objective_revisions.select { |r| r.updated_on <= effective_date }
        .max_by{ |r| r.sequence_number }
    end
  end
end
