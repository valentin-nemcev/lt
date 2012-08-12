require 'spec_helper'

class ActionDispatch::TestResponse
  def body_json
    body.present? or fail 'response body is empty'
    JSON.parse body
  end
end

def create_task(fields = {})
  post '/tasks/', :task => {
    :type => fields.fetch(:type, 'action'),
    :objective => fields.fetch(:objective, 'Test objective')
  }, :format => :json
  OpenStruct.new response.body_json.fetch 'task'
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

    describe 'single action creation' do
      before(:each) do
        post '/tasks/', :task => {
          :type => 'action',
          :objective => test_ojective
        }, :format => :json

        @returned_action = OpenStruct.new response.body_json.fetch 'task'
      end
      attr_accessor :returned_action

      let(:stored_action) do
        get '/tasks/', :format => :json
        OpenStruct.new response.body_json.fetch 0
      end

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

    describe 'subtask creation' do
      let(:project) { create_task type: 'project' }
      let(:project_url) { "/tasks/#{project.id}" }

      before(:each) do
        post '/tasks/', :task => {
          :type => 'action',
          :objective => test_ojective,
          :project_id => project.id,
        }, :format => :json

        @returned_subtask = OpenStruct.new response.body_json.fetch 'task'
      end
      attr_accessor :returned_subtask

      let(:returned_task) { OpenStruct.new response.body_json.fetch 'task' }

      describe 'returned subtask' do
        subject { returned_subtask }
        its(:project_id) { should eq(project.id) }
      end

      describe 'persisted subtask' do
        subject do
          get "/tasks/#{returned_subtask.id}", :format => :json
          OpenStruct.new response.body_json.fetch 'task'
        end

        its(:project_id) { should eq(project.id) }
      end
    end
  end

  describe '/:task_id' do
    let(:task) { create_task }
    let(:task_url) { "/tasks/#{task.id}" }

    describe 'PUT' do
      describe 'objective update' do
        before(:each) do
          task.objective = 'New objective'
          put task_url, :task => task.marshal_dump, :format => :json
        end

        let(:returned_task) { OpenStruct.new response.body_json.fetch 'task' }

        it 'returns updated task' do
          returned_task.objective.should eq('New objective')
        end

        it 'persists updated task' do
          get task_url, :format => :json
          returned_task.objective.should eq('New objective')
        end
      end
    end

    describe 'DELETE' do
      let(:task) { create_task }
      let(:task_url) { "/tasks/#{task.id}" }

      before(:each) do
        delete task_url
        @delete_response = response
      end
      attr_accessor :delete_response

      let(:task_list) do
        get '/tasks/', :format => :json
        response.body_json
      end

      let(:deleted_task_response) do
        get task_url, :format => :json
        response
      end

      specify { delete_response.should be_successful }
      specify { task_list.should be_empty }
      specify { deleted_task_response.should be_not_found }
    end
  end
end
