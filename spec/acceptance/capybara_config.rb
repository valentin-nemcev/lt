require 'capybara/rails'
require 'capybara/rspec'

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
Capybara.javascript_driver = :selenium
Capybara.default_driver = :selenium

Capybara.ignore_hidden_elements = true


