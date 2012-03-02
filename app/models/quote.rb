class Quote < ActiveRecord::Base

  def self.find_random options = {}
    logger.info options
    r = self.order('RAND()')
    r = r.where(['id <> ?', options[:after]]) if options[:after]
    r.first
  end

end
