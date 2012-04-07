require 'spec_helper'

describe Task do
  describe '.create' do
    it 'sets creation date' do
      task = Task.create
      task.created_at.should be <= Time.now
    end
  end
end
