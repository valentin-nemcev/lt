require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'

  require 'capybara/rails'
  require 'capybara/rspec'

  require 'acceptance/helpers.rb'

  Capybara.javascript_driver = :selenium
  Capybara.server_port = 9000
  Capybara.app_host = 'http://lt.dev.lan:9000'
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app,
      :browser => :remote,
      :url => "http://mainframe.lan:4444/wd/hub",
      :desired_capabilities => :chrome)
  end
  Capybara.default_driver = :selenium
  Capybara.ignore_hidden_elements = true

  RSpec.configure do |config|
    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = false

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    config.treat_symbols_as_metadata_keys_with_true_values = true

    config.include RSpec::Rails::RequestExampleGroup, :type => :api
    config.include AcceptanceHelpers, :acceptance

    config.after(:each, :acceptance, :pause_if_failed) do
      pause_if_failed example
    end


    DatabaseCleaner.logger = Rails.logger

    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
    end

    config.before(:each) do |example|
      metadata = example.example.metadata
      DatabaseCleaner.strategy = if metadata[:acceptance]
                                   :deletion
                                 else
                                   :transaction
                                 end
      DatabaseCleaner.start
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end

end

Spork.each_run do
  load 'acceptance/selector_matcher.rb'
  load 'acceptance/helpers.rb'
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
end
