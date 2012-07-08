require 'spec_helper'

# TODO: Use new rspec named subject everywhere
describe Task::Project do

  def create_project(attrs={})
    attrs.reverse_merge! objective: 'Test project!'
    described_class.new attrs
  end

  let(:project) { create_project }
  subject { project }

  it { should_not be_actionable }

  it 'could not be completed directly' do
    expect { project.complete! }.to raise_error
  end

  context 'new' do
    it { should_not be_completed }
  end
end
