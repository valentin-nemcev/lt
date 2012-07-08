require 'spec_helper'

# TODO: Use new rspec named subject everywhere
describe Task::Action do

  def create_action(attrs={})
    attrs.reverse_merge! objective: 'Test action!'
    described_class.new attrs
  end

  let(:single_action) { create_action.tap{ |a| a.stub subtasks: [] } }
  subject { single_action }

  context 'new' do
    it { should be_actionable }
    it { should_not be_completed }

    it 'should not have completion date' do
      single_action.completed_on.should be_nil
    end

  end

  context 'new with completion date' do
    subject { create_action created_on: 2.days.ago, completed_on: 1.day.ago }
    it { should_not be_actionable }
    it { should     be_completed }

    # TODO: Replace date "literals" with lets
    it 'should have completion date', :with_frozen_time do
      subject.completed_on.should eq(1.day.ago)
    end

  end

  context 'completed' do
    subject { single_action.complete! }
    it { should be_completed }
    it { should_not be_actionable }
    it 'should have completion date', :with_frozen_time do
      subject.completed_on.should eq(Time.current)
    end

    context 'as of different date' do
      let(:original) { create_action }
      let!(:as_of_different_date) { original.as_of original.effective_date }
      it 'should be completed when original is completed' do
        original.complete!
        as_of_different_date.should be_completed
      end
      it 'and vice versa' do
        as_of_different_date.complete!
        original.should be_completed
      end
    end
  end

  context 'completed before created' do
    it 'should raise error' do
      expect { single_action.complete! on: 1.day.ago }.to raise_error
    end
  end

  context 'completed, then completion undone' do
    subject { single_action.complete!.undo_complete! }
    it { should_not be_completed }

    context 'as of different date' do
      let(:original) { create_action.complete! }
      let!(:as_of_different_date) { original.as_of original.effective_date }
      it 'should not be completed when original is not completed' do
        original.undo_complete!
        as_of_different_date.should_not be_completed
      end
      it 'and vice versa' do
        as_of_different_date.undo_complete!
        original.should_not be_completed
      end
    end
  end

  context 'completed on future date' do
    let(:future_date) { 1.day.from_now }
    let(:completed_in_future) { single_action.complete! on: future_date }

    context 'seen from now' do
      subject { completed_in_future }
      it { should_not be_completed }
      it 'should have completion date in the future', :with_frozen_time do
        subject.completed_on.should eq(future_date)
      end
    end

    context 'seen from future date' do
      subject { completed_in_future.as_of(future_date) }
      it { should be_completed }
    end
  end

  context 'blocked' do
    subject { create_action.tap { |a| a.stub(:blocked? => true) } }
    it { should_not be_actionable }
  end
end
