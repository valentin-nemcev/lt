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

    # TODO: change to related(:subtasks)
    def subtasks
      related :type => :composition, :relation => :sub
    end


    include Attributes::Computed::TaskMethods

    has_computed_attribute :state, computed_from:
      {self: :state, subtasks: :state} \
    do |self_state, subtasks_states|
      # self_state.nil? and fail 'self_state is nil'
      if self_state != :underway
        self_state
      elsif subtasks_states.all?{ |s| s == :completed }
        :completed
      else
        :underway
      end
    end

    include Attributes::TaskMethods
  end
end
