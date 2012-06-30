module Task
  class Base < Core
    include PersistenceMethods
    include RelationMethods
    include ObjectiveMethods
  end
end
