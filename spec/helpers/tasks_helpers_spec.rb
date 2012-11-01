require 'spec_helper'

describe TasksHelper do
  describe '#fetch_related_tasks' do
    attr_reader :storage
    before { @storage = stub(:storage, fetch: nil) }

    context 'without task ids' do
      specify { fetch_related_tasks({}).should eq({}) }
    end
    context 'with task ids' do
      before(:each) do
        storage.stub(:fetch).with(:task_id1).and_return(:task1)
        storage.stub(:fetch).with(:task_id2).and_return(:task2)
        storage.stub(:fetch).with(:task_id3).and_return(:task3)
        storage.stub(:fetch).with(:task_id4).and_return(:task4)
      end

      example do
        fetch_related_tasks({
          some_other_params: :param_value,
          supertask_ids: {
            task_rel1_name: [:task_id3],
            task_rel2_name: [:task_id1, :task_id2]
          },
          subtask_ids: {
            task_rel2_name: [:task_id4]
          }
        }).should eq({
          task_rel1_name: {supertasks: [:task3], subtasks: []},
          task_rel2_name: {supertasks: [:task1, :task2], subtasks: [:task4]}
        })
      end
    end
  end
end
