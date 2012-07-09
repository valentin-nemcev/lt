module Task
  module Records
    # TODO: Fix namespace resolution
    class Action < ::Task::Records::Task
      attr_accessible :completed_on
    end
  end
end

