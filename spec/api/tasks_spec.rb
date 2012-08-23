require 'spec_helper'

class JSONStruct < OpenStruct
  def as_json
    marshal_dump
  end
end

class ActionDispatch::TestResponse
  def json_body(response_field = nil)
    body.present? or fail 'response body is empty'
    resp = JSON.parse body
    resp = resp.fetch(response_field) if response_field
    JSONStruct.new resp
  end
end

def request(method, uri, data = {})
  unless method.in? [:get, :post, :put, :delete]
    raise ArgumentError, "Invalid method #{method}"
  end
  data = data.as_json
  params = data.merge :format => :json
  public_send method, uri, params
  response
end

def create_task(fields = {})
  fields.reverse_merge!({
    type:      'action',
    objective: 'Test objective',
    state:     'considered',
  })
  request(:post, '/tasks/', :task => fields).json_body('task')
end

# TODO: Use url helpers
describe 'tasks', :type => :api do
  attr_accessor :user_fixture
  before(:all) do
    User.delete_all;
    user_fixture = User.create!
  end

  describe 'get list of tasks' do
    subject(:list) { request(:get, '/tasks/').json_body }

    context 'no tasks' do
      its(:tasks) { should be_empty }
    end

    its(:valid_new_task_states) { should_not be_empty }
  end

  describe 'post a task' do
    let(:test_ojective) { 'Test objective!' }
    let(:task_fields) {{
      type:      'action',
      objective: test_ojective,
      state:     'considered',
    }}

    let(:post_response) { request :post, '/tasks/', :task => task_fields }
    let(:returned_action) { post_response.json_body 'task' }
    let(:persisted_action) do
      request(:get, "/tasks/#{returned_action.id}").json_body 'task'
    end

    specify { post_response.should be_successful }
    specify { persisted_action.should eq(returned_action) }

    subject { returned_action }

    its(:id)         { should_not be_nil }
    its(:type)       { should eq('action') }
    its(:state)      { should eq('considered') }
    its(:objective)  { should eq(test_ojective) }

    its(:valid_next_states) { should_not be_empty }

    context 'with no other tasks' do
      before(:each) { task_fields.delete :project_id }

      its(:project_id) { should be_nil }
    end

    context 'with a parent project' do
      let(:project) { create_task type: 'project' }
      before(:each) { task_fields[:project_id] = project.id }

      its(:project_id) { should eq(project.id) }
    end

    context 'with invalid field' do
      before(:each) { task_fields[:objective] = '' }
      let(:task_errors) { post_response.json_body.task_errors }

      specify { post_response.should be_bad_request}
      specify { task_errors.should include('empty_objective') }
    end
  end

  describe 'put a task' do
    let(:task) { create_task }
    let(:task_url) { "/tasks/#{task.id}" }
    let(:returned_task) do
      request(:put, task_url, :task => task).json_body 'task'
    end
    let(:persisted_task) { request(:get, task_url).json_body 'task' }

    specify { persisted_task.should eq(returned_task) }

    describe 'with updated fields' do
      before(:each) do
        task.objective = 'New objective'
        task.state = 'underway'
      end
      subject { returned_task }

      its(:objective) { should eq('New objective') }
      its(:state)     { should eq('underway') }
    end
  end

  describe 'delete a task' do
    let(:task) { create_task type: 'action' }
    let(:task_url) { "/tasks/#{task.id}" }
    let(:task_list) { request(:get, '/tasks/').json_body.tasks }

    let!(:delete_response) { request :delete, task_url }
    let(:deleted_task_response) { request :get, task_url }

    context 'without subtasks' do
      specify { delete_response.should be_successful }
      specify { task_list.should be_empty }
      specify { deleted_task_response.should be_not_found }
    end

    context 'with subtasks' do
      let(:task) do
        create_task(type: 'project').tap do |task|
          self.action = create_task type: 'action', project_id: task.id
        end
      end
      attr_accessor :action

      let(:action_response) do
        request(:get, "/tasks/#{action.id}").json_body 'task'
      end

      specify { delete_response.should be_successful }
      specify { task_list.should have(1).task }
      specify { action_response.project_id.should be_nil }
    end
  end
end
