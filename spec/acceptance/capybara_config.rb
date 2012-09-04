require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'

Capybara.server_port = 9000
Capybara.app_host = 'http://lt.dev.lan:9000'

Capybara.register_driver :selenium do |app|
  opts = {
    :browser => :remote,
    :url => "http://mainframe.lan:4444/wd/hub",
    :desired_capabilities => :chrome
  }
  Capybara::Selenium::Driver.new app, opts
end
Capybara.register_driver :poltergeist do |app|
  opts = {
    :inspector => 'echo'
  }
  Capybara::Poltergeist::Driver.new(app, opts)
end
# Capybara.default_driver = :poltergeist
Capybara.default_driver = :selenium

Capybara.ignore_hidden_elements = true


