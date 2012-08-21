module Task
  class NoStateRevisionsError < TaskError; end
  module StateMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def valid_new_task_states
        StateRevision.valid_next_states_for :new_task
      end
    end

    def initialize(attrs={})
      super

      fields[:state_revisions] =
        Revisions::Sequence.new(created_on: created_on,
                                     revisions: attrs[:state_revisions])
      attrs[:state].try{ |obj| update_state obj, on: created_on }

      raise NoStateRevisionsError if fields[:state_revisions].empty?
    end

    def state_revisions
      fields[:state_revisions].to_a
    end

    def state
      fields[:state_revisions].last_on(effective_date).state
    end

    def update_state(state, opts={})
      revs = fields[:state_revisions]
      updated_on = opts.fetch :on, effective_date
      attrs = {
        state: state,
        updated_on: updated_on,
        sequence_number: revs.last_sequence_number + 1,
      }
      revs.add_revision StateRevision.new(attrs)
      return self
    end

    def valid_next_states
      StateRevision.valid_next_states_for self
    end
  end
end
