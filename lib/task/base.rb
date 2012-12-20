module Task
  class Base < Core
    include Persistable

    include Attributes::Editable::TaskMethods
    has_editable_attribute :state,     revision_class: Attributes::StateRevision
    has_editable_attribute :objective, revision_class: Attributes::ObjectiveRevision


    include RelationMethods
    has_relation :composition, supers: :projects, subs: :subtasks


    include Attributes::Computed::TaskMethods

    has_computed_attribute :state, computed_from:
      {self: :state, subtasks: :state} \
    do |self_state, subtasks_states|
      if subtasks_states.empty? || self_state != :underway
        self_state
      elsif subtasks_states.any? { |s| s == :underway }
        :underway
      elsif subtasks_states.any? { |s| s == :considered }
        :considered
      else
        :completed
      end
    end

    include Attributes::TaskMethods

    def destroy(&related_task_destroyer)
      related(:subtasks).each(&related_task_destroyer)
      super
    end
  end
end
