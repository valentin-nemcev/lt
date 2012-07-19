require 'spec_helper'

feature 'Correct title', :acceptance do
  scenario 'Opening main page' do
    visit '/'
    find('head title').should have_content('Life Tracker')
  end
end
