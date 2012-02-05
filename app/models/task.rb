class Task < ActiveRecord::Base
  acts_as_nested_set
  attr_protected :lft, :rgt, :depth

  default_scope order('lft')

  def as_json options = {}
    options.merge! :except => [:lft, :rgt, :depth]
    super options
  end
end
