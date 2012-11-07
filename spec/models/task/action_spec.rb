require 'spec_helper'

describe Task::Action do

  def create_action(attrs={})
    attrs.reverse_merge! objective: 'Test action!', state: 'underway'
    described_class.new attrs
  end

  let(:current_time) { Time.current }
  let(:clock) { stub('Clock', current: current_time) }
  let(:creation_date) { Time.current }
  let(:single_action) do
    create_action(on: creation_date, clock: clock).tap{ |a|
    }
  end
  subject { single_action }
end
