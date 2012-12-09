module Task
  class TaskError < StandardError; end;

  class Base < Core
    include Persistable

    # TODO: Reduce nesting and remove TaskMethods
    include Attributes::Editable::TaskMethods
    has_editable_attribute :state,     revision_class: Attributes::StateRevision
    has_editable_attribute :objective, revision_class: Attributes::ObjectiveRevision


    include RelationMethods
    has_relation :composition, supers: :projects, subs: :subtasks


    include Attributes::Computed::TaskMethods

    has_computed_attribute :state, computed_from:
      {self: :state, subtasks: :state} \
    do |self_state, subtasks_states|
      state = subtasks_states.first
      fail state if state && state.include?('objective')
      # self_state.nil? and fail 'self_state is nil'
      if self_state != 'underway'
        self_state
      elsif subtasks_states.present? && subtasks_states.all? do |s|
          s.in? ['completed', 'canceled']
        end
        'completed'
      elsif subtasks_states.present? && subtasks_states.all? do |s|
          s.in? ['completed', 'canceled', 'considered']
        end
        'considered'
      else
        'underway'
      end
    end

    include Attributes::TaskMethods

    def destroy(&related_task_destroyer)
      related(:subtasks).each(&related_task_destroyer)
      super
    end
  end
end
