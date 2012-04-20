require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false


    def now
      Time.current
    end

    def with_frozen_time(time=nil)
      time ||= now
      # Databases and other places may truncate usecs, so we truncate them too to
      # avoid problems with comparisons
      time = time.change :usec => 0
      Timecop.freeze(time) { yield time }
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end
