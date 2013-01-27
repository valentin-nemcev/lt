require 'spec_helper'
require 'api/helpers'

# TODO: Use url helpers
describe 'tasks', :api do
  include_context :api_helpers
  attr_accessor :user_fixture
  before(:all) do
    User.delete_all;
    user_fixture = User.create!
  end


  let(:new_project_fields) {{
    objective: 'New project objective',
    state:     'underway',
  }}

  let(:beginning_date)        { Time.zone.parse('2012-01-01 00:00').httpdate }
  let(:project_creation_date) { Time.zone.parse('2012-01-01 12:00').httpdate }

  shared_examples :project_creation do
    describe 'new project creation event' do
      subject {
        events.find_struct(date: project_creation_date, type: 'task_creation')
      }
      its(:id)        { should_not be_nil }
      its(:task_id)   { should eq(project_id) }
      its(:date)      { should eq(project_creation_date) }
    end
  end

  shared_examples :new_project_updates do
    describe 'new project objective update event' do
      subject { events.find_struct(
        type:           'task_update',
        task_id:        project_id,
        attribute_name: 'objective',
        date:           project_creation_date
      )}
      its(:updated_value) { should eq('New project objective') }
      its(:task_id)       { should eq(project_id) }
    end

    describe 'new project subtask count update event' do
      subject { events.find_struct(
        type:           'task_update',
        task_id:        project_id,
        attribute_name: 'subtask_count',
        date:           project_creation_date
      )}
      its(:updated_value) { should eq(0) }
      its(:task_id)       { should eq(project_id) }
    end
  end


  let(:new_action_fields) {{
    supertask_ids: {composition: [project_id]},
    objective:     'New action objective',
    state:         'underway',
  }}

  let(:action_creation_date) { Time.zone.parse('2012-01-02 12:00').httpdate }

  shared_examples :action_creation do
    describe 'new action creation event' do
      subject {
        events.find_struct(date: action_creation_date, type: 'task_creation')
      }
      its(:id)        { should_not be_nil }
      its(:task_id)   { should_not be_nil }
      its(:date)      { should eq(action_creation_date) }
    end
  end

  shared_examples :new_action_updates do
    describe 'new action objective update event' do
      subject { events.find_struct(
        type:           'task_update',
        attribute_name: 'objective',
        date:           action_creation_date
      )}
      its(:updated_value) { should eq('New action objective') }
      its(:task_id)       { should eq(action_id) }
    end

    describe 'new action computed state update event' do
      subject { events.find_struct(
        type:           'task_update',
        task_id:        action_id,
        attribute_name: 'computed_state',
        date:           action_creation_date,
      )}
      its(:updated_value) { should eq('underway') }
    end

    describe 'new action project subtask count update' do
      subject { events.find_struct(
        type:           'task_update',
        task_id:        project_id,
        attribute_name: 'subtask_count',
        date:           action_creation_date,
      )}
      its(:updated_value) { should eq(1) }
    end
  end

  shared_examples :new_action_relations do
    describe 'new action to project relation addition' do
      subject { events.find_struct(
        type:         'relation_addition',
        subtask_id:   action_id,
        supertask_id: project_id
      )}
      its(:relation_type) { should eq('composition') }
      its(:date)          { should eq(action_creation_date) }
    end
  end

  let(:updated_action_fields) { new_action_fields.merge(
    supertask_ids: {composition: []},
    objective: 'Updated action objective',
    state:     'done'
  ) }

  let(:update_date)   { Time.zone.parse('2012-01-03 12:00').httpdate }

  shared_examples :updated_action_updates do
    describe 'updated action objective update' do
      subject { events.find_struct(
        type:           'task_update',
        attribute_name: 'objective',
        date:           update_date
      )}
      its(:updated_value) { should eq('Updated action objective') }
      its(:task_id)       { should eq(action_id) }
    end

    describe 'updated action project subtask count state update' do
      subject { events.find_struct(
        type:           'task_update',
        task_id:        project_id,
        attribute_name: 'subtask_count',
        date:           update_date,
      )}
      its(:updated_value) { should eq(0) }
    end
  end

  shared_examples :updated_action_relations do
    describe 'updated action to project relation removal' do
      subject { events.find_struct(
        type:         'relation_removal',
        subtask_id:   action_id,
        supertask_id: project_id
      )}
      its(:relation_type) { should eq('composition') }
      its(:date)          { should eq(update_date) }
    end
  end

  let(:project_create_response) do
    request :post, '/tasks/', :task => new_project_fields,
      :effective_date => project_creation_date,
      :beginning_date => beginning_date
  end

  let(:project_id) do
    project_create_response.json_body.events
      .find_struct(date: project_creation_date, type: 'task_creation').id
  end

  let(:project_url) { "/tasks/#{project_id}" }


  let(:action_create_response) do
    request :post, '/tasks/', :task => new_action_fields,
      :effective_date => action_creation_date,
      :beginning_date => beginning_date
  end

  let(:action_update_response) do
    request :put, action_url, :task => updated_action_fields,
      :effective_date => update_date,
      :beginning_date => beginning_date
  end

  let(:action_id) do
    action_create_response.json_body.events
      .find_struct(date: action_creation_date, type: 'task_creation').id
  end

  let(:action_url) { "/tasks/#{action_id}" }

  describe 'get persisted tasks' do
    subject(:get_response) { request :get, '/tasks/',
      :beginning_date => beginning_date
    }

    context 'no tasks' do
      it { should be_successful }
      describe do
        subject { get_response.json_body }
        its(:events) { should be_empty }
      end
      # its(:valid_new_task_states) { should_not be_empty }
    end

    context 'with a project and an updated action' do
      before do
        project_create_response.should be_successful
        action_create_response.should be_successful
        action_update_response.should be_successful
      end

      describe do
        subject(:events) { get_response.json_body.events }
        let(:event_ids) do
          events.collect{ |u| u['id'] }
        end
        specify { event_ids.should be_unique }

        include_examples :project_creation
        include_examples :action_creation

        include_examples :new_project_updates
        include_examples :new_action_updates
        include_examples :updated_action_updates

        include_examples :new_action_relations
        include_examples :updated_action_relations
      end
    end
  end

  describe 'create' do
    specify { project_create_response.should be_successful }
    let(:project_response_body) { project_create_response.json_body }

    describe do
      subject(:events) { project_response_body.events }

      include_examples :project_creation
      include_examples :new_project_updates
    end

    specify { action_create_response.should be_successful }
    let(:action_response_body) { action_create_response.json_body }

    describe do
      subject(:events) { action_response_body.events }

      include_examples :action_creation
      include_examples :new_action_updates
      include_examples :new_action_relations
    end

    # describe pending: 'TODO' do
    #   its(:valid_next_states) { should_not be_empty }

    #   context 'with invalid field' do
    #     before(:each) { task_fields[:objective] = '' }
    #     let(:task_errors) { post_response.json_body.task_errors }

    #     specify { post_response.should be_bad_request}
    #     specify { task_errors.should include('empty_objective') }
    #   end
    # end
  end

  describe 'update' do
    specify { action_update_response.should be_successful }
    let(:response_body) { action_update_response.json_body }

    subject(:events) { response_body.events }

    include_examples :updated_action_updates
    include_examples :updated_action_relations
  end

  describe 'delete a project with subtasks' do
    subject(:get_response) { request :get, '/tasks/',
      :beginning_date => beginning_date
    }
    let!(:delete_response) do
      project_id
      action_id
      request :delete, project_url
    end
    let(:events)     { get_response.json_body.events }

    specify { delete_response.should be_successful }
    specify { events.should have(0).events }
  end
end
