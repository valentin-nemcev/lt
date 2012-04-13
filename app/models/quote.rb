class Quote < ActiveRecord::Base

  belongs_to :user

  attr_accessible :content, :source
  def self.find_random options = {}
    r = self.order('RAND()')
    r = r.where(['id <> ?', options[:after]]) if options[:after]
    r.first
  end

end
