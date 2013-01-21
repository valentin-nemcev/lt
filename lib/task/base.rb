module Task
  class Base < Core
    include Persistable

    include Attributes::EditableMethods
    has_editable_attribute :state,     revision_class: Attributes::StateRevision
    has_editable_attribute :objective, revision_class: Attributes::ObjectiveRevision

    def editable_attributes_updated(revisions)
      completed_rev = revisions.detect do |rev|
        rev.attribute_name == :state &&
          rev.updated_value.in?([:done, :canceled])
      end
      return if completed_rev.nil?

      self.completion_date = completed_rev.update_date
    end

    include RelationMethods
    has_relation :composition, supers: :projects, subs: :subtasks
    has_relation :dependency,  supers: :blocking, subs: :dependent


    include Attributes::ComputedMethods

    has_computed_attribute :computed_state, computed_from:
      {self: :state, subtasks: :computed_state} \
    do |self_state, subtasks_states|
      if !subtasks_states.empty? && self_state == :underway &&
           subtasks_states.all? { |s| s.in? [:done, :subtasks_done, :canceled] }
        :subtasks_done
      else
        self_state
      end
    end

    has_computed_attribute :blocked, computed_from:
      {blocking: :state} \
    do |blocking|
      blocking.any? { |s| s.in? [:underway, :considered] }
    end

    has_computed_attribute :subtask_count, computed_from:
      {subtasks: :state} \
    do |subtasks|
      subtasks.count
    end

    has_computed_attribute :type, computed_from:
      {subtasks: :state} \
    do |subtasks|
      subtasks.empty? ? :action : :project
    end

    has_computed_attribute :last_state_change_date, computed_from:
      {self: :computed_state} \
    do |_, date|
      date
    end

    def self.order_hash(els)
      els.each_with_index.
        flat_map { |els, i| Array(els).map { |e| [e, i] } }.
        each_with_object({}) { |(e, i), h| h[e] = i }.freeze
    end

    STATES_ORDER = order_hash [
      [:done, :subtasks_done, :canceled],
      :underway,
      :considered]
    TYPES_ORDER = order_hash [:action, :project]
    has_computed_attribute :sort_rank, computed_from:
      {self: [:computed_state, :blocked, :last_state_change_date]} \
    do |state, blocked, last_state_change_date|
      blocked = nil if state.in? [:done, :subtasks_done, :canceled]
      [STATES_ORDER[state], blocked, last_state_change_date.to_i]
    end

    include Attributes::Methods

    def destroy(&related_task_destroyer)
      related(:subtasks).each(&related_task_destroyer)
      super
    end
  end
end
