require 'spec_helper'

class ActionDispatch::TestResponse
  def body_json
    body.present? or fail 'response body is empty'
    JSON.parse body
  end
end


describe '/tasks', :type => :api do
  before(:all) { User.delete_all; User.create! }
  let(:user_fixture) { User.first! }

  describe 'GET' do
    context 'no tasks' do
      it 'should return empty list of tasks' do
        get '/tasks/', :format => :json
        tasks = response.body_json
        tasks.should be_empty
      end
    end
  end

  describe 'POST' do
    let(:test_ojective) { 'Test objective!' }

    context 'with new action' do
      before(:each) do
        post '/tasks/', :task => {
          :type => 'action',
          :objective => test_ojective
        }, :format => :json

        @returned_action = OpenStruct.new response.body_json.fetch 'task'
        get '/tasks/', :format => :json
        @stored_action = OpenStruct.new response.body_json.fetch 0
      end

      let(:returned_action) { @returned_action }
      let(:stored_action)   { @stored_action }

      specify { response.should be_successful }

      describe 'returned action' do
        subject { returned_action }

        its(:id)         { should_not be_nil }
        its(:type)       { should eq('action') }
        its(:objective)  { should eq(test_ojective) }
        its(:project_id) { should be_nil }
      end

      specify 'stored action should equal returned action' do
        stored_action.should eq(returned_action)
      end
    end
  end
end
