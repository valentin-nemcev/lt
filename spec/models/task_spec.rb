require 'spec_helper'

describe Task do


  context 'with super or subtasks', :pending do
    context 'with added supertask' do
      let(:supertask1) { create_task }
      let(:supertask2) { create_task }
      subject do
        create_task.tap do |t|
          t.add_supertask supertask1
          t.add_supertask supertask2
        end
      end

      it 'allows acces to supertasks collection' do
        subject.supertasks.to_a.should =~ ([supertask1, supertask2])
      end

      it 'supertasks collection is readonly and enumerable' do
        subject.supertasks.should be_an(Enumerable)
        expect {subject.supertasks << :potato }.to raise_error
      end
    end
  end

  context 'blocked task', :pending do
    let(:blocked_task) do
      create_task.tap { |blocked_task|
        2.times { blocked_task.blocking_tasks.create! }
      }.reload
    end

    subject { blocked_task }

    it { should be_blocked }
    it { should_not be_actionable }
    it { should_not be_completed }

    context 'with some blocking tasks completed' do
      subject do
        blocked_task.tap { |t| t.blocking_tasks.first.complete! }
      end

      it { should be_blocked }
      it { should_not be_actionable }
    end

    context 'with all blocking tasks completed' do
      subject do
        blocked_task.tap { |t| t.blocking_tasks.each(&:complete!) }
      end

      it { should_not be_blocked }
      it { should be_actionable }
    end

  end

end
