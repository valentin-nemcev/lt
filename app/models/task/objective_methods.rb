module Task
  class NoObjectiveRevisionsError < TaskError; end
  module ObjectiveMethods
    def initialize(attrs={})
      super

      fields[:objective_revisions] =
        Revisions::Sequence.new(created_on: created_on,
                                     revisions: attrs[:objective_revisions])
      attrs[:objective].try{ |obj| update_objective obj, on: created_on }

      raise NoObjectiveRevisionsError if fields[:objective_revisions].empty?
    end

    def objective_revisions
      fields[:objective_revisions].to_a
    end

    def objective
      fields[:objective_revisions].last_on(effective_date).objective
    end

    def update_objective(objective, opts={})
      revs = fields[:objective_revisions]
      updated_on = opts.fetch :on, effective_date
      attrs = {
        objective: objective,
        updated_on: updated_on,
        sequence_number: revs.last_sequence_number + 1,
      }
      revs.add_revision ObjectiveRevision.new(attrs)
      return self
    end
  end
end
