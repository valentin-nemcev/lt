module Task
  class Base < Core
    include Persistable

    include RelationMethods
    has_relation :composition, supers: :projects, subs: :subtasks
    has_relation :dependency,  supers: :blocking, subs: :dependent

    include Attributes::EditableMethods
    has_editable_attribute :state,     revision_class: Attributes::StateRevision
    has_editable_attribute :objective, revision_class: Attributes::ObjectiveRevision

    def events_after_attribute_update(revisions)
      revisions.detect do |rev|
        rev.attribute_name == :state &&
          rev.updated_value.in?([:done, :canceled])
      end.try do |completed_rev|
        update_date = completed_rev.update_date
        subtasks = filtered_relations(:for => :subtasks, :on => update_date).nodes
        subtasks.all?(&:completed?) or raise Error,
          "Can't complete task with incomplete subtasks"

        self.completion_date = update_date
      end
      [self.completion_event].compact
    end


    include Attributes::ComputedMethods

    COMPLETED_STATES = [:done, :subtasks_done, :canceled]
    has_aggregate_computed_attribute \
      :subtask_count,
      :initial_value => 0,
      :computed_from => {:subtasks => :_id},
      :added   => Proc.new { |initial| initial += 1 },
      :removed => Proc.new { |initial| initial -= 1 }

    has_aggregate_computed_attribute \
      :completed_subtask_count,
      :initial_value => 0,
      :computed_from => {:subtasks => :computed_state},
      :added   => Proc.new { |i, s| i += s.in?(COMPLETED_STATES) ? 1 : 0 },
      :removed => Proc.new { |i, s| i -= s.in?(COMPLETED_STATES) ? 1 : 0 }

    has_aggregate_computed_attribute \
      :blocking_count,
      :initial_value => 0,
      :computed_from => {:blocking => :computed_state},
      :added   => Proc.new { |i, s| i += !s.in?(COMPLETED_STATES) ? 1 : 0 },
      :removed => Proc.new { |i, s| i -= !s.in?(COMPLETED_STATES) ? 1 : 0 }

    has_computed_attribute \
      :computed_state,
      :computed_from => [:state, :subtask_count, :completed_subtask_count],
      :changed => Proc.new { |state, total, completed|
        if total > 0 && state == :underway && total == completed
          :subtasks_done
        else
          state
        end
      }

    has_computed_attribute \
      :blocked,
      :computed_from => [:blocking_count],
      :changed => Proc.new { |c| c > 0 }

    has_computed_attribute \
      :type,
      :computed_from => [:subtask_count],
      :changed => Proc.new { |c| c > 0 ? :project : :action }

    has_computed_attribute \
      :last_state_change_date,
      :computed_from => [:computed_state],
      :changed => Proc.new { |_, date| date }

    def self.order_hash(els)
      els.each_with_index.
        flat_map { |els, i| Array(els).map { |e| [e, i] } }.
        each_with_object({}) { |(e, i), h| h[e] = i }.freeze
    end

    STATES_ORDER = order_hash [
      [:done, :subtasks_done, :canceled],
      :underway,
      :considered]

    has_computed_attribute \
      :sort_rank,
      :computed_from => [:computed_state, :blocked, :last_state_change_date],
      :changed => Proc.new { |state, blocked, last_state_change_date|
        blocked = nil if state.in? COMPLETED_STATES
        [STATES_ORDER[state], blocked, last_state_change_date.to_i]
      }

    include Attributes::Methods

    def destroy(&related_task_destroyer)
      related(:subtasks).each(&related_task_destroyer)
      super
    end
  end
end
