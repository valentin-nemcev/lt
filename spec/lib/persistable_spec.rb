require 'lib/spec_helper'

require 'persistable'

describe Persistable do
  class PersistableObject
    include Persistable
    def fields
      @fields
    end
    protected :fields

    def initialize(attrs={})
      @fields = {}
      super
    end
  end


  let(:test_id)         { 1 }
  let(:another_test_id) { 2 }


  context 'not persisted' do
    let(:not_persisted) { PersistableObject.new }
    specify { not_persisted.id.should be_nil }
    specify { not_persisted.should_not be_persisted }

    context 'with added id' do
      let(:persisted) do
        not_persisted.tap { |task| task.id = test_id }
      end

      specify { persisted.id.should eq(test_id) }
      specify { not_persisted.should_not be_persisted }
    end
  end

  context 'persisted' do
    let(:persisted) do
      PersistableObject.new id: test_id
    end

    specify { persisted.id.should eq(test_id) }
    specify { persisted.should be_persisted }

    it 'should not allow change of id' do
      expect {
        persisted.id = another_test_id
      }.to raise_error(Persistable::AlreadyPersistedError)

      expect {
        persisted.id = persisted.id
      }.to_not raise_error(Persistable::AlreadyPersistedError)
    end

    context 'with removed id' do
      let(:not_persisted) do
        persisted.tap { |task| task.id = nil}
      end
      specify { not_persisted.should_not be_persisted }
    end
  end

  context 'persisted clone' do
    it 'should be persisted if original is persisted' do
      original = PersistableObject.new
      clone = original.clone
      original.id = 1
      clone.id.should eq(1)
    end
  end
end

