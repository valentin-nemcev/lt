require 'lib/spec_helper'

require 'persistable'
require 'models/task'
require 'models/task/core'

describe Task::Core do
  let(:current_time) { Time.current }
  let(:clock) { stub('Clock', current: current_time) }

  describe '#created_on' do
    context 'created without date' do
      subject(:task) { described_class.new clock: clock }
      its(:created_on) { should eq(current_time) }
    end

    context 'created with passed creation date' do
      let(:task_creation_date) { 2.days.ago }
      subject(:task) { described_class.new created_on: task_creation_date }
      its(:created_on) { should eq(task_creation_date) }
    end
  end

  describe '#effective_date' do
    subject(:task) { described_class.new on: task_creation_date, clock: clock }

    context 'created in past' do
      let(:task_creation_date) { 2.days.ago }
      its(:effective_date) { should eq(current_time) }
    end

    context 'created in future' do
      let(:task_creation_date) { 2.days.from_now }
      its(:effective_date) { should eq(task_creation_date) }
    end
  end
end

