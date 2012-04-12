class UIState < ActiveRecord::Base
  belongs_to :user
  validates :user, presence: true

  attr_accessible  :component, :state

  serialize :state, Hash
end
