module Task
  class TaskError < StandardError; end;

  class Base < Core
    include RelationMethods
    include ObjectiveMethods
    include StateMethods
  end
end
