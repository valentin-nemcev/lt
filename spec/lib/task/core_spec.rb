require 'lib/spec_helper'

require 'persistable'
require 'task'
require 'task/core'

describe Task::Core do
  let(:current_time) { Time.current }
  let(:clock) { stub('Clock', current: current_time) }

  describe '#creation_date' do
    context 'created without date' do
      subject(:task) { described_class.new clock: clock }
      its(:creation_date) { should eq(current_time) }
    end

    context 'created with passed creation date' do
      let(:task_creation_date) { 2.days.ago }
      subject(:task) { described_class.new creation_date: task_creation_date }
      its(:creation_date) { should eq(task_creation_date) }
    end
  end
end
