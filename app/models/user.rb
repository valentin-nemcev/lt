class User < ActiveRecord::Base
  attr_accessible :login, :name

  validates :login, :uniqueness => { :case_sensitive => false }
end
