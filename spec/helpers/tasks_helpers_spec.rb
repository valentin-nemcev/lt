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
      end

      example do
        fetch_related_tasks({
          task_rel1_name_ids: [:task_id3],
          task_rel2_name_ids: [:task_id1, :task_id2]
        }).should eq({
          task_rel1_names: [:task3],
          task_rel2_names: [:task1, :task2]
        })
      end
    end
  end
end
