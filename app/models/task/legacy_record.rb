module Task
  class LegacyRecord < ActiveRecord::Base
    self.table_name = 'legacy_tasks'

    acts_as_nested_set

    default_scope order('lft')

    belongs_to :user

  end
end
