require 'spec_helper'

class ActionDispatch::TestResponse
  def body_json
    JSON.parse body
  end
end

describe '/tasks', :type => :api do
  describe 'GET' do
    context 'no tasks' do
      it 'should return empty list of tasks' do
        get '/tasks.json/'
        tasks = response.body_json
        tasks.should be_empty
      end
    end
  end
end
