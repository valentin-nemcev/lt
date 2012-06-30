module Task
  class Record < ActiveRecord::Base
    self.table_name = 'tasks'

    acts_as_nested_set

    default_scope order('lft')

    belongs_to :user

  end
end
