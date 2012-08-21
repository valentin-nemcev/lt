require 'spec_helper'

class ActionDispatch::TestResponse
  def body_json
    body.present? or fail 'response body is empty'
    JSON.parse body
  end
end

#TODO: Create request-response helpers

def create_task(fields = {})
  post '/tasks/', :task => {
    :type => fields.fetch(:type, 'action'),
    :objective => fields.fetch(:objective, 'Test objective'),
    :state => fields.fetch(:state, 'considered'),
    :project_id => fields[:project_id],
  }, :format => :json
  OpenStruct.new response.body_json.fetch 'task'
end

describe '/tasks', :type => :api do
  before(:all) { User.delete_all; User.create! }
  let(:user_fixture) { User.first! }

  describe 'GET' do
    context 'no tasks' do
      before(:each) { get '/tasks/', :format => :json }

      it 'should return empty list of tasks' do
        tasks = response.body_json.fetch 'tasks'
        tasks.should be_empty
      end

      it 'should return valid new task states' do
        states = response.body_json.fetch 'valid_new_task_states'
        states.should match_array(%w{considered underway})
      end
    end
  end

  describe 'POST' do
    let(:test_ojective) { 'Test objective!' }

    describe 'single action creation' do
      before(:each) do
        post '/tasks/', :task => {
          :type => 'action',
          :objective => test_ojective,
          :state => 'considered',
        }, :format => :json

        @returned_action = OpenStruct.new response.body_json.fetch 'task'
      end
      attr_accessor :returned_action

      let(:stored_action) do
        get '/tasks/', :format => :json
        OpenStruct.new response.body_json.fetch('tasks').fetch 0
      end

      specify { response.should be_successful }

      describe 'returned action' do
        subject { returned_action }

        its(:id)         { should_not be_nil }
        its(:type)       { should eq('action') }
        its(:state)      { should eq('considered') }
        its(:objective)  { should eq(test_ojective) }
        its(:project_id) { should be_nil }

        its(:valid_next_states)  {
          should match_array(%w{considered underway completed canceled})
        }
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
          :state => 'considered',
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

      describe 'state update' do
        before(:each) do
          task.state = 'underway'
          put task_url, :task => task.marshal_dump, :format => :json
        end

        let(:returned_task) { OpenStruct.new response.body_json.fetch 'task' }

        it 'returns updated task' do
          returned_task.state.should eq('underway')
        end

        it 'persists updated task' do
          get task_url, :format => :json
          returned_task.state.should eq('underway')
        end
      end
    end

    describe 'DELETE' do
      let(:task_list) do
        get '/tasks/', :format => :json
        response.body_json.fetch 'tasks'
      end

      context 'single task' do
        let(:task) { create_task }
        let(:task_url) { "/tasks/#{task.id}" }

        before(:each) do
          delete task_url
          @delete_response = response
        end
        attr_accessor :delete_response

        let(:deleted_task_response) do
          get task_url, :format => :json
          response
        end

        specify { delete_response.should be_successful }
        specify { task_list.should be_empty }
        specify { deleted_task_response.should be_not_found }
      end

      context 'task with relations' do
        let(:task) { create_task type: 'project' }
        let(:action) { create_task type: 'action', project_id: task.id }
        before(:each) do
          task; action
          delete task_url
          @delete_response = response
        end
        attr_accessor :delete_response

        let(:action_response) do
          get "/tasks/#{action.id}", :format => :json
          OpenStruct.new response.body_json.fetch 'task'
        end

        specify { delete_response.should be_successful }
        specify { task_list.should have(1).task }
        specify { action_response.project_id.should be_nil }
      end
    end
  end
end
