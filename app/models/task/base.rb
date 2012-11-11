module Task
  class TaskError < StandardError; end;

  class Base < Core
    include Persistable

    include RelationMethods
    include RevisableAttributes

    has_revisable_attribute :state, revision_class: StateRevision
    has_revisable_attribute :objective, revision_class: ObjectiveRevision

    def self.valid_new_task_states
      StateRevision.valid_next_states_for :new_task
    end

    def valid_next_states
      StateRevision.valid_next_states_for self
    end


    has_relation :composition, supers: :projects, subs: :subtasks

    def subtasks
      related :type => :composition, :relation => :sub
    end
  end
end
