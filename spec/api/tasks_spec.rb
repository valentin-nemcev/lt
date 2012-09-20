require 'spec_helper'

class JSONStruct < OpenStruct
  def as_json
    marshal_dump
  end

  def matches?(fields)
    fields.all? do |name, value|
      self.send(name.to_sym) == value
    end
  end
end

class Hash
  def to_struct
    JSONStruct.new self
  end
end

RSpec::Matchers.define :be_unique do
  def duplicates(ary)
    ary.group_by{ |e| e }.select{ |e, dups| dups.length > 1 }.keys
  end

  match do |array|
    duplicates(array).empty?
  end

  failure_message_for_should do |array|
    "array has duplicated elements: #{duplicates(array)}"
  end

end

class Array
  def find_struct(fields)
    structs = map(&:to_struct)
    matches = structs.find_all{ |s| s.matches? fields }
    l = matches.size
    l == 1 or fail "Found #{l == 0 ? 'no' : l} #{'struct'.pluralize(l)}" \
                   " matching #{fields}" \
                   " Existing #{'struct'.pluralize(structs.size)} were: \n" +
                   structs.map(&:inspect).join("\n")
    matches.first
  end
end

module ResponseHelpers
  def json_body(response_field = nil)
    body.present? or fail 'response body is empty'
    resp = JSON.parse body
    resp = resp.fetch(response_field) if response_field
    JSONStruct.new resp
  end

  def successful?
    super or fail "Request was not successful: \n" \
                  "#{code}: #{status_message}\n" \
                  "#{body}"
  end
end

class ActionDispatch::TestResponse
  include ResponseHelpers
end


shared_context :api_helpers do
  let(:session) { ActionDispatch::Integration::Session.new(Rails.application) }
  def request(method, uri, data = {})
    unless method.in? [:get, :post, :put, :delete]
      raise ArgumentError, "Invalid method #{method}"
    end
    data = data.as_json
    params = data.merge :format => :json
    session.public_send method, uri, params
    session.response
  end
end


def create_task(fields = {})
  fields.reverse_merge!({
    type:      'action',
    objective: 'Test objective',
    state:     'considered',
  })
  response = request(:post, '/tasks/', :task => fields)
  response.json_body.task_creations.fetch(0).fetch('id')
end

# TODO: Use url helpers
describe 'tasks', :type => :api do
  attr_accessor :user_fixture
  before(:all) do
    User.delete_all;
    user_fixture = User.create!
  end
  include_context :api_helpers


  let(:new_task_fields) {{
    type:      'action',
    objective: 'New task objective',
    state:     'considered',
  }}

  let(:creation_date) { Time.zone.parse('2012-01-01 10:00').httpdate }

  shared_examples :task_creation do
    describe do
      subject(:task_creation) { task_creations.fetch(0).to_struct }
      its(:id)        { should_not be_nil }
      its(:task_id)   { should_not be_nil }
      its(:task_type) { should eq('action') }
      its(:date)      { should eq(creation_date) }
    end
  end

  let(:updated_task_fields) { new_task_fields.merge(
    objective: 'Updated task objective',
    state:     'underway'
  ) }

  let(:update_date)   { Time.zone.parse('2012-01-01 12:00').httpdate }

  shared_examples :new_task_updates do
    describe do
      subject(:objective_update) { task_updates.find_struct(
        attribute_name: 'objective',
        date:           creation_date
      )}
      its(:updated_value) { should eq('New task objective') }
      its(:task_id)       { should eq(task_id) }
    end

    describe do
      subject(:state_update) { task_updates.find_struct(
        attribute_name: 'state',
        date:           creation_date
      )}
      its(:updated_value) { should eq('considered') }
      its(:task_id)       { should eq(task_id) }
    end
  end

  shared_examples :updated_task_updates do
    describe do
      subject(:objective_update) { task_updates.find_struct(
        attribute_name: 'objective',
        date:           update_date
      )}
      its(:updated_value) { should eq('Updated task objective') }
      its(:task_id)       { should eq(task_id) }
    end

    describe do
      subject(:state_update) { task_updates.find_struct(
        attribute_name: 'state',
        date:           update_date
      )}
      its(:updated_value) { should eq('underway') }
      its(:task_id)       { should eq(task_id) }
    end
  end

  let(:create_response) do
    request :post, '/tasks/', :task => new_task_fields,
      :effective_date => creation_date
  end

  let(:task_id) do
    create_response.json_body.task_creations.fetch(0).fetch('id')
  end

  let(:task_url) { "/tasks/#{task_id}" }

  describe 'get persisted tasks' do
    subject(:get_response) { request :get, '/tasks/' }

    context 'no tasks' do
      it { should be_successful }
      describe do
        subject { get_response.json_body }
        its(:task_creations) { should be_empty }
        its(:task_updates)   { should be_empty }
      end
      # its(:valid_new_task_states) { should_not be_empty }
    end

    context 'with single updated task' do
      let!(:udpate_response) do
        request :put, task_url, :task => updated_task_fields,
          :effective_date => update_date
      end

      describe do
        subject(:response_body) { get_response.json_body }
        let(:event_ids) do
          (response_body.task_creations +
           response_body.task_updates).map{ |u| u['id'] }
        end
        specify { event_ids.should be_unique }

        describe do
          subject(:task_creations) { response_body.task_creations }
          it { should have(1).creation }
          include_examples :task_creation
        end

        describe do
          subject(:task_updates) { response_body.task_updates }
          it { should have(4).updates }
          include_examples :new_task_updates
          include_examples :updated_task_updates
        end

      end
    end

  end

  describe 'create' do
    specify { create_response.should be_successful }
    let(:response_body) { create_response.json_body }

    describe do
      subject(:task_creations) { response_body.task_creations }
      it { should have(1).creation }
      include_examples :task_creation
    end

    describe do
      subject(:task_updates) { response_body.task_updates }
      it { should have(2).updates }

      include_examples :new_task_updates
    end

    # describe pending: 'TODO' do
    #   its(:valid_next_states) { should_not be_empty }

    #   context 'with no other tasks' do
    #     before(:each) { task_fields.delete :project_id }

    #     its(:project_id) { should be_nil }
    #   end

    #   context 'with a parent project' do
    #     let(:project) { create_task type: 'project' }
    #     before(:each) { task_fields[:project_id] = project.id }

    #     its(:project_id) { should eq(project.id) }
    #   end

    #   context 'with invalid field' do
    #     before(:each) { task_fields[:objective] = '' }
    #     let(:task_errors) { post_response.json_body.task_errors }

    #     specify { post_response.should be_bad_request}
    #     specify { task_errors.should include('empty_objective') }
    #   end
    # end
  end

  describe 'update' do
    let!(:udpate_response) do
      request :put, task_url, :task => updated_task_fields,
        :effective_date => update_date
    end

    specify { udpate_response.should be_successful }
    let(:response_body) { udpate_response.json_body }

    describe do
      subject(:task_updates) { response_body.task_updates }
      it { should have(2).updates }

      include_examples :updated_task_updates
    end
  end

  describe 'delete a task' do
    let(:task_id) { create_task type: 'action' }
    let(:task_url) { "/tasks/#{task_id}" }

    subject(:get_response) { request :get, '/tasks/' }
    let!(:delete_response) { request :delete, task_url }
    let(:task_creations) { get_response.json_body.task_creations }
    let(:task_updates)   { get_response.json_body.task_updates }

    context 'without subtasks' do
      specify { delete_response.should be_successful }
      specify { task_creations.should be_empty }
      specify { task_updates.should be_empty }
    end

    # context 'with subtasks', :pending do
      # let(:task) do
        # create_task(type: 'project').tap do |task|
          # self.action = create_task type: 'action', project_id: task_id
        # end
      # end
      # attr_accessor :action_id

      # let(:action_response) do
        # request(:get, "/tasks/#{action_id}").json_body 'task'
      # end

      # specify { delete_response.should be_successful }
      # specify { task_list.should have(1).task }
      # specify { action_response.project_id.should be_nil }
    # end
  end
end
