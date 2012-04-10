class User < ActiveRecord::Base
  attr_accessible :login, :name

  validates :login, :uniqueness => { :case_sensitive => false }

  has_many :tasks
  has_many :quotes
end
