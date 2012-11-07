require 'spec_helper'

describe Task::Project do

  def create_project(attrs={})
    attrs.reverse_merge! objective: 'Test project!', state: 'underway'
    described_class.new attrs
  end

  subject(:project) { create_project }
end
