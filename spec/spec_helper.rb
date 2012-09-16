require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'


  require 'config.rb'
  require 'acceptance/capybara_config.rb'

  RSpec.configure do |config|
    config.use_transactional_fixtures = false

    DatabaseCleaner.logger = Rails.logger

    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
    end

    config.before(:each) do |example|
      metadata = example.example.metadata
      DatabaseCleaner.strategy =
        metadata[:acceptance] ? :deletion : :transaction
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end
end

Spork.each_run do
  require 'acceptance/selector_matcher.rb'
  require 'acceptance/input_options.rb'
  require 'acceptance/helpers.rb'
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
end
