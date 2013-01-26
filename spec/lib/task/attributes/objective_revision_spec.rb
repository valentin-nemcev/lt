require 'lib/spec_helper'

require 'persistable'
require 'task'
require 'task/attributes'
require 'task/attributes/revision'
require 'task/attributes/editable_revision'
require 'task/attributes/objective_revision'

describe Task::Attributes::ObjectiveRevision do
  let(:test_objective) { 'Test objective' }
  let(:test_date)      { Time.current }
  let(:test_sn)        { 12 }

  def create_objective_revision(objective)
    described_class.new updated_value: objective,
      update_date: test_date, sequence_number: test_sn
  end

  it 'should not allow empty objective' do
    [nil, '', '    '].each do |empty_objective|
      expect do
        create_objective_revision(empty_objective)
      end.to raise_error \
        Task::Attributes::ObjectiveRevision::EmptyObjectiveError
    end
  end

  it 'should remove excess space from objective' do
    ["  	Task objective\n", "Task\n	    objective"].each do |objective|
      rev = create_objective_revision(objective)
      rev.updated_value.should == 'Task objective'
    end
  end
end
