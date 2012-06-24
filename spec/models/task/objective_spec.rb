require 'spec_helper'

describe Task::ObjectiveRevision do
  it 'should not allow empty objective' do
    [nil, '', '    '].each do |empty_objective|
      expect do
        described_class.new empty_objective, Time.current
      end.to raise_error Task::InvalidObjectiveError
    end
  end
end
