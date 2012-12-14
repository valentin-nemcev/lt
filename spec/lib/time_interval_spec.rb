require 'lib/spec_helper'
require 'time_interval'

RSpec::Matchers.define :include_with_end do |expected|
  match do |actual|
    actual.include_with_end? expected
  end
end

describe TimeInterval do
  let(:given_date) { Time.current }
  let(:never)   { Time::NEVER }
  let(:forever) { Time::FOREVER }

  context 'beginning at given date' do
    subject { described_class.beginning_at given_date }

    its(:beginning) { should be given_date }
    its(:ending)    { should be forever }

    it { should_not be_empty }
    it { should_not include never }
    it { should include given_date }
    it { should_not include forever }
    it { should include_with_end forever }
  end

  context 'ending at given date' do
    subject { described_class.ending_at given_date }

    its(:beginning) { should be never }
    its(:ending)    { should be given_date }

    it { should_not be_empty }
    it { should include never }
    it { should_not include given_date }
    it { should include_with_end given_date }
    it { should_not include forever }
  end

  context 'for all time' do
    subject { described_class.for_all_time }

    its(:beginning) { should be never }
    its(:ending)    { should be forever }

    it { should_not be_empty }
    it { should include never }
    it { should include given_date }
    it { should_not include forever }
    it { should include_with_end forever }
  end

  context 'empty' do
    subject(:empty) { described_class.empty }

    specify do
      expect{ empty.beginning }.to raise_error NoMethodError
    end
    specify do
      expect{ empty.ending }.to raise_error NoMethodError
    end

    it { should be_empty }
    it { should_not include never }
    it { should_not include given_date }
    it { should_not include forever }
    it { should_not include_with_end forever }
  end

  context 'without gap between endpoints' do
    specify { described_class.new(date1, date1).should be_empty }
    specify { described_class.new(date2, date1).should be_empty }
  end

  let(:date1) { given_date + 1.day }
  let(:date2) { given_date + 2.day }
  let(:date3) { given_date + 3.day }
  let(:date4) { given_date + 4.day }
  describe 'intersection' do
    context 'when there is an intersection' do
      let(:first)        { described_class.new date1, date3 }
      let(:second)       { described_class.new date2, date4 }
      let(:intersection) { described_class.new date2, date3 }
      specify { (first & second).should eq intersection }
      specify { (first.overlaps_with? second).should be_true }
    end

    context 'when there is no intersection' do
      let(:first)        { described_class.new date1, date2 }
      let(:second)       { described_class.new date3, date4 }
      specify { (first & second).should be_empty }
      specify { (first.overlaps_with? second).should be_false }
    end

    context 'when there is no intersection and no gap' do
      let(:first)        { described_class.new date1, date2 }
      let(:second)       { described_class.new date2, date4 }
      specify { (first & second).should be_empty }
      specify { (first.overlaps_with? second).should be_false }
    end

    context 'with unbounded' do
      let(:first)        { described_class.beginning_at date1 }
      let(:second)       { described_class.ending_at date4 }
      let(:intersection) { described_class.new date1, date4 }
      specify { (first & second).should eq intersection }
      specify { (first.overlaps_with? second).should be_true }
    end

    context 'empty' do
      let(:first)        { described_class.new date1, date4 }
      let(:second)       { described_class.empty }
      specify { (first & second).should be_empty }
      specify { (second & first).should be_empty }
      specify { (first.overlaps_with? second).should be_false }
      specify { (second.overlaps_with? first).should be_false }
    end
  end
end
