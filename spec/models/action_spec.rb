require 'spec_helper'

describe Action do
  def create_action(attrs={})
    Action.new attrs
  end

  describe 'without connections' do
    let(:single_action) { create_action }
    subject { single_action }

    context 'after creation' do
      it 'should have creation date', :with_frozen_time do
        single_action.created_on.should eq(Time.current)
      end

      it 'should have effective date same as creation date' do
        single_action.effective_date.should eq(single_action.created_on)
      end

      it 'should not have completion date' do
        single_action.completed_on.should be_nil
      end

      it { should be_actionable }
      it { should_not be_completed }

      context 'seen from now' do
        it {should be}
      end

      context 'seen from past' do
        subject { single_action.as_of(1.second.ago) }
        it {should be_nil}
      end

      context 'created in past' do
        subject { create_action on: 2.days.ago }
        it 'should have creation date in past', :with_frozen_time do
          subject.created_on.should eq(2.days.ago)
        end
        it 'should have effective date set to now', :with_frozen_time do
          subject.effective_date.should eq(Time.current)
        end
      end

      context 'created in future' do
        subject { create_action on: 2.days.from_now }
        it 'should have effective date in future', :with_frozen_time do
          subject.effective_date.should eq(2.days.from_now)
        end
      end
    end

    context 'completed' do
      subject { single_action.complete! }
      it { should be_completed }
      it { should_not be_actionable }
      it 'should have completion date', :with_frozen_time do
        subject.completed_on.should eq(Time.current)
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
  end
end
