require 'lib/spec_helper'

require 'revisions/sequence'
include Revisions

describe Sequence do
  before(:each) { stub_const('RevisionClass', stub()) }

  let(:owner) { stub('Attribute owner') }

  let(:creation_date) { 4.hours.ago }
  let(:update_date)   { 3.hours.ago }

  def stub_revision(*args)
    stub(*args).tap do |revision_stub|
      revision_stub.stub(:'owner=')
    end
  end

  let(:first_revision)  { stub_revision(
    'first revision',  update_date: creation_date, sequence_number: 1) }
  let(:second_revision) { stub_revision(
    'second revision', update_date: update_date,   sequence_number: 2) }

  let(:initial_arguments) do
    { creation_date: creation_date, revision_class: RevisionClass, owner: owner }
  end


  subject(:sequence) { Sequence.new initial_arguments }

  context 'no revisions' do
    it { should be_empty }
    its(:last) { should be_nil }
  end

  context 'with revisions' do
    before(:each) { sequence.set_revisions [first_revision, second_revision] }

    it { should_not be_empty }
    its(:last) { should eq(second_revision) }
  end

  context 'with revisions passed on creation' do
    before(:each) do
      initial_arguments.merge! revisions: [first_revision, second_revision]
    end

    it { should_not be_empty }
  end

  describe '#set_revisions' do
    context 'with no revisions' do
      it 'should set revision sequence' do
        sequence.set_revisions [first_revision, second_revision]
        sequence.to_a.should eq([first_revision, second_revision])
      end

      it 'should set revisions in correct order' do
        sequence.set_revisions [second_revision, first_revision]
        sequence.to_a.should eq([first_revision, second_revision])
      end

      let(:revisions_with_incorrect_dates) { [
        stub_revision(
          'first revision',  update_date: update_date,   sequence_number: 1),
        stub_revision(
          'second revision', update_date: creation_date, sequence_number: 2),
      ] }
      it 'should not allow revision list with incorrect dates' do
        expect do
          sequence.set_revisions revisions_with_incorrect_dates
        end.to raise_error DateSequenceError
      end

      let(:revisions_with_incorrect_sns) { [
        stub_revision(
          'first revision',  update_date: creation_date, sequence_number: 1),
        stub_revision(
          'second revision', update_date: update_date,   sequence_number: 1),
      ] }
      it 'should not allow revision list with incorrect sequence numbers' do
        expect do
          sequence.set_revisions revisions_with_incorrect_sns
        end.to raise_error SequenceNumberError
      end
    end

    context 'with revisions' do
      before(:each) do
        sequence.set_revisions [first_revision, second_revision]
      end

      it 'should replace existing revisions' do
        sequence.set_revisions [first_revision]
        sequence.to_a.should eq([first_revision])
      end
    end

    it 'should set revisions owner' do
      first_revision.should_receive(:'owner=').with(owner)
      second_revision.should_receive(:'owner=').with(owner)
      sequence.set_revisions [first_revision, second_revision]
    end
  end

  describe '#new_revision' do
    let(:revision_attrs) { {updated_value: :value, update_date: creation_date} }
    let(:new_sn) { 1 }
    let(:new_revision) { stub_revision('new revision', revision_attrs) }

    before(:each) do
      revision_attrs.update sequence_number: new_sn
      RevisionClass.should_receive(:new)
        .with(revision_attrs)
        .and_return(new_revision)
    end

    it 'should return new revision' do
      sequence.new_revision(revision_attrs).should be(new_revision)
    end

    context 'with no revisions' do
      it 'should create new revision and add it to sequence' do
        sequence.new_revision revision_attrs
        sequence.to_a.should eq([new_revision])
      end

      it 'should not allow revisions before sequence was created' do
        new_revision.stub update_date: 1.second.until(creation_date)
        expect do
          sequence.new_revision revision_attrs
        end.to raise_error DateSequenceError
      end
    end

    context 'with revisions' do
      before(:each) do
        sequence.set_revisions [first_revision, second_revision]
      end
      let(:new_sn) { 3 }

      it 'should create new revision and add it to sequence' do
        new_revision.stub update_date: 1.second.since(update_date)
        sequence.new_revision revision_attrs
        sequence.to_a.should eq([first_revision, second_revision, new_revision])
      end

      it 'should not allow adding revisions with incorrect date order' do
        new_revision.stub update_date: 1.second.until(update_date)
        expect do
          sequence.new_revision revision_attrs
        end.to raise_error DateSequenceError
      end

      it 'should preserve order of revisions with same date' do
        new_revision.stub update_date: update_date
        sequence.new_revision revision_attrs
        sequence.to_a.should eq([first_revision, second_revision, new_revision])
      end
    end

    it 'should set revisions owner' do
      new_revision.should_receive(:'owner=').with(owner)
      sequence.new_revision revision_attrs
    end
  end

  describe '#last_before' do
    context 'without revisions' do
      it 'should return nothing' do
        sequence.last_before(creation_date).should be_nil
      end
    end

    context 'with revisions' do
      before(:each) do
        sequence.set_revisions [first_revision, second_revision]
      end

      specify 'without date it should return nothing' do
        sequence.last_before(nil).should be_nil
      end

      specify 'with date in past it should return nothing' do
        sequence.last_before(1.day.until creation_date).should be_nil
      end

      specify 'with date on revision it should return revision before it' do
        sequence.last_before(update_date).should be first_revision
      end

      specify 'with date in future it should return revision before it' do
        sequence.last_before(1.day.since update_date).should be second_revision
      end
    end
  end

  describe '#all_in_interval' do
    context 'without revisions' do
      it 'should return nothing' do
        sequence.all_in_interval(TimeInterval.for_all_time).should be_empty
      end
    end

    context 'with revisions' do
      before(:each) do
        sequence.set_revisions [first_revision, second_revision]
      end

      it 'should return revisions in given interval' do
        sequence.all_in_interval(TimeInterval.new creation_date, update_date).
          should eq([first_revision])
        sequence.all_in_interval(TimeInterval.beginning_on update_date).
          should eq([second_revision])
      end

      specify 'with unbounded interval it should return all revisions' do
        sequence.all_in_interval(TimeInterval.for_all_time).
          should eq([first_revision, second_revision])
      end
    end
  end
end
