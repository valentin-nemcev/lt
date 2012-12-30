module Task
  class Base < Core
    include Persistable

    include Attributes::EditableMethods
    has_editable_attribute :state,     revision_class: Attributes::StateRevision
    has_editable_attribute :objective, revision_class: Attributes::ObjectiveRevision


    include RelationMethods
    has_relation :composition, supers: :projects, subs: :subtasks


    include Attributes::ComputedMethods

    has_computed_attribute :computed_state, computed_from:
      {self: :state, subtasks: :computed_state} \
    do |self_state, subtasks_states|
      if subtasks_states.empty? || self_state != :underway
        self_state
      elsif subtasks_states.all? { |s| s.in? [:completed, :canceled] }
        :completed
      else
        :underway
      end
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

    STATES_ORDER = order_hash [[:completed, :canceled], :underway, :considered]
    TYPES_ORDER = order_hash [:action, :project]
    has_computed_attribute :sort_rank, computed_from:
      {self: [:computed_state, :last_state_change_date]} \
    do |state, last_state_change_date|
      [STATES_ORDER[state], last_state_change_date.to_i]
    end

    include Attributes::Methods

    def destroy(&related_task_destroyer)
      related(:subtasks).each(&related_task_destroyer)
      super
    end
  end
end
