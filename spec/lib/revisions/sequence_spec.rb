
require 'lib/spec_helper'

require 'revisions/sequence'
include Revisions

describe Sequence do
  let(:creation_date) { 4.hours.ago }
  let(:update_date) { 3.hours.ago }
  let(:first_revision) do
    stub('first revision',  updated_on: creation_date, sequence_number: 1)
  end
  let(:second_revision) do
    stub('second revision', updated_on: update_date,   sequence_number: 2)
  end
  let(:second_revision2) do
    stub('second revision', updated_on: update_date,   sequence_number: 3)
  end

  let(:revision_before_creation) do
    stub('revision_before_creation',
         updated_on: 1.hour.until(creation_date),
         sequence_number: 1,
      )
  end
  let(:revisions_with_incorrect_dates) { [
      stub('first revision',  updated_on: update_date,   sequence_number: 1),
      stub('second revision', updated_on: creation_date, sequence_number: 2),
  ] }

  let(:revisions) { [first_revision, second_revision] }

  subject(:sequence) do
    Sequence.new(created_on: creation_date)
  end

  describe '#set_revisions' do
    it 'should set revision history' do
      sequence.add_revision second_revision2
      sequence.set_revisions revisions
      sequence.to_a.should eq(revisions)
    end

    it 'should set revisions in correct order' do
      sequence.set_revisions revisions.reverse
      sequence.to_a.should eq(revisions)
    end

    it 'should not allow revision list with incorrect dates' do
      expect do
        sequence.set_revisions revisions_with_incorrect_dates
      end.to raise_error DateSequenceError
    end
  end

  describe '#add_revision' do
    it 'should add to revision history' do
      sequence.add_revision first_revision
      sequence.add_revision second_revision
      sequence.to_a.should eq(revisions)
    end

    it 'should not allow adding revisions in incorrect order' do
      expect do
        sequence.add_revision second_revision
        sequence.add_revision first_revision
      end.to raise_error SequenceNumberError
    end

    it 'should not allow revisions before sequence was created' do
      expect do
        sequence.add_revision revision_before_creation
      end.to raise_error DateSequenceError
    end

    it 'should not allow adding revisions with incorrect date order' do
      expect do
        sequence.add_revision revisions_with_incorrect_dates.first
        sequence.add_revision revisions_with_incorrect_dates.second
      end.to raise_error DateSequenceError
    end
  end

  describe '#last_sequence_number' do
    context 'no revisions' do
      its(:last_sequence_number) { should eq(0) }
    end

    context 'with revisions' do
      before(:each) do
        sequence.set_revisions revisions
      end

      its(:last_sequence_number) { should eq(2) }
    end
  end

  describe '#empty?' do
    context 'no revisions' do
      it { should be_empty }
    end

    context 'with revisions' do
      before(:each) do
        sequence.set_revisions revisions
      end

      it { should_not be_empty }
    end
  end

  describe '#last_on' do
    context 'no revisions' do
      it 'should return nil regardless of date' do
        sequence.last_on(creation_date).should be_nil
        sequence.last_on(update_date).should be_nil
      end
    end

    context 'with revisions' do
      before(:each) do
        sequence.set_revisions revisions
      end

      specify { sequence.last_on(1.hour.until(creation_date))
                                               .should be_nil              }
      specify { sequence.last_on(creation_date).should eq(first_revision)  }
      specify { sequence.last_on(update_date  ).should eq(second_revision) }
      specify { sequence.last_on(1.hour.since(update_date))
                                               .should eq(second_revision) }
    end
  end
end
