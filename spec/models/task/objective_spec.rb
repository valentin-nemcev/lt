require 'spec_helper'

describe Task::ObjectiveRevision do
  let(:test_objective) { 'Test objective' }
  let(:test_date)      { Time.current }
  let(:test_sn)        { 12 }

  it 'should have objective, update date and sequence number' do
    rev = described_class.new objective: test_objective,
      updated_on: test_date, sequence_number: test_sn
    rev.objective.should eq(test_objective)
    rev.updated_on.should eq(test_date)
    rev.sequence_number.should eq(test_sn)
  end

  it 'should not allow empty objective' do
    [nil, '', '    '].each do |empty_objective|
      expect do
        described_class.new objective: empty_objective,
          updated_on: test_date, sequence_number: test_sn
      end.to raise_error(Task::InvalidObjectiveError)
    end
  end
end
