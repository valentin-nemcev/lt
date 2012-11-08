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
    type:      'project',
    objective: 'New project objective',
    state:     'underway',
  }}

  let(:project_creation_date) { Time.zone.parse('2012-01-01 9:00').httpdate }

  shared_examples :project_creation do
    describe do
      subject(:project_creation) {
        task_creations.find_struct(task_type: 'project')
      }
      its(:id)        { should_not be_nil }
      its(:task_id)   { should eq(project_id) }
      its(:task_type) { should eq('project') }
      its(:date)      { should eq(project_creation_date) }
    end
  end

  shared_examples :new_project_updates do
    describe do
      subject(:objective_update) { task_updates.find_struct(
        task_id:        project_id,
        attribute_name: 'objective',
        date:           project_creation_date
      )}
      its(:updated_value) { should eq('New project objective') }
      its(:task_id)       { should eq(project_id) }
    end

    describe do
      subject(:state_update) { task_updates.find_struct(
        task_id:        project_id,
        attribute_name: 'state',
        date:           project_creation_date
      )}
      its(:updated_value) { should eq('underway') }
      its(:task_id)       { should eq(project_id) }
    end
  end


  let(:new_action_fields) {{
    type:          'action',
    supertask_ids: {composition: [project_id]},
    objective:     'New action objective',
    state:         'underway',
  }}

  let(:action_creation_date) { Time.zone.parse('2012-01-01 10:00').httpdate }

  shared_examples :action_creation do
    describe do
      subject(:action_creation) {
        task_creations.find_struct(task_type: 'action')
      }
      its(:id)        { should_not be_nil }
      its(:task_id)   { should_not be_nil }
      its(:task_type) { should eq('action') }
      its(:date)      { should eq(action_creation_date) }
    end
  end

  shared_examples :new_action_updates do
    describe do
      subject(:objective_update) { task_updates.find_struct(
        attribute_name: 'objective',
        date:           action_creation_date
      )}
      its(:updated_value) { should eq('New action objective') }
      its(:task_id)       { should eq(action_id) }
    end

    describe do
      subject(:action_state_update) { task_updates.find_struct(
        task_id:        action_id,
        attribute_name: 'state',
        date:           action_creation_date,
      )}
      its(:updated_value) { should eq('underway') }
    end
  end

  shared_examples :new_action_relations do
    describe do
      subject(:composite_relation_addition) { relation_additions.find_struct(
        subtask_id: action_id,
        supertask_id: project_id
      )}
      its(:relation_type) { should eq('composition') }
      its(:date)          { should eq(action_creation_date) }
    end
  end

  let(:updated_action_fields) { new_action_fields.merge(
    objective: 'Updated action objective',
    state:     'completed'
  ) }

  let(:update_date)   { Time.zone.parse('2012-01-01 12:00').httpdate }

  shared_examples :updated_action_updates do
    describe do
      subject(:objective_update) { task_updates.find_struct(
        attribute_name: 'objective',
        date:           update_date
      )}
      its(:updated_value) { should eq('Updated action objective') }
      its(:task_id)       { should eq(action_id) }
    end

    describe do
      subject(:state_update) { task_updates.find_struct(
        task_id:        action_id,
        attribute_name: 'state',
        date:           update_date
      )}
      its(:updated_value) { should eq('completed') }
    end

    describe do
      subject(:project_state_update) { task_updates.find_struct(
        task_id:        project_id,
        attribute_name: 'state',
        date:           action_creation_date,
      )}
      its(:updated_value) { should eq('completed') }
    end
  end

  let(:project_create_response) do
    request :post, '/tasks/', :task => new_project_fields,
      :effective_date => project_creation_date
  end

  let(:project_id) do
    project_create_response.json_body.task_creations
      .find_struct(task_type: 'project').id
  end

  let(:project_url) { "/tasks/#{project_id}" }


  let(:action_create_response) do
    request :post, '/tasks/', :task => new_action_fields,
      :effective_date => action_creation_date
  end

  let(:action_update_response) do
    request :put, action_url, :task => updated_action_fields,
      :effective_date => update_date
  end

  let(:action_id) do
    action_create_response.json_body.task_creations
      .find_struct(task_type: 'action').id
  end

  let(:action_url) { "/tasks/#{action_id}" }

  describe 'get persisted tasks' do
    subject(:get_response) { request :get, '/tasks/' }

    context 'no tasks' do
      it { should be_successful }
      describe do
        subject { get_response.json_body }
        its(:task_creations)     { should be_empty }
        its(:task_updates)       { should be_empty }
        its(:relation_additions) { should be_empty }
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
        subject(:response_body) { get_response.json_body }
        let(:event_ids) do
          [response_body.task_creations,
           response_body.task_updates,
           response_body.relation_additions].flatten.collect{ |u| u['id'] }
        end
        specify { event_ids.should be_unique }

        describe do
          subject(:task_creations) { response_body.task_creations }
          it { should have(2).creations }
          include_examples :project_creation
          include_examples :action_creation
        end

        describe do
          subject(:task_updates) { response_body.task_updates }
          it { should have(7).updates }
          include_examples :new_project_updates
          include_examples :new_action_updates
          include_examples :updated_action_updates
        end

        describe do
          subject(:relation_additions) { response_body.relation_additions }
          it { should have(1).addition }
          include_examples :new_action_relations
        end
      end
    end
  end

  describe 'create' do
    specify { project_create_response.should be_successful }
    let(:project_response_body) { project_create_response.json_body }

    describe do
      subject(:task_creations) { project_response_body.task_creations }
      it { should have(1).creation }
      include_examples :project_creation
    end

    describe do
      subject(:task_updates) { project_response_body.task_updates }
      it { should have(2).updates }
      include_examples :new_project_updates
    end

    specify { action_create_response.should be_successful }
    let(:action_response_body) { action_create_response.json_body }

    describe do
      subject(:task_creations) { action_response_body.task_creations }
      it { should have(1).creation }
      include_examples :action_creation
    end

    describe do
      subject(:task_updates) { action_response_body.task_updates }
      it { should have(2).updates }
      include_examples :new_action_updates
    end

    describe do
      subject(:relation_additions) { action_response_body.relation_additions }
      it { should have(1).addition }
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

    describe do
      subject(:task_updates) { response_body.task_updates }
      it { should have(3).updates }

      include_examples :updated_action_updates
    end
  end

  describe 'delete a project with subtasks' do
    subject(:get_response) { request :get, '/tasks/' }
    let!(:delete_response) do
      project_id
      action_id
      request :delete, project_url
    end
    let(:task_creations)   { get_response.json_body.task_creations }
    let(:task_updates)     { get_response.json_body.task_updates }
    let(:relation_additions) { get_response.json_body.relation_additions }

    specify { delete_response.should be_successful }
    specify { task_creations.should have(0).creations }
    specify { task_updates.should have(0).updates }
    specify { relation_additions.should have(0).additions }
  end
end
