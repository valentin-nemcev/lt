require 'lib/spec_helper'

require 'persistable'

describe Persistable do
  let(:initial_attrs) { Hash.new }
  subject(:persistable) { persistable_class.new initial_attrs }

  context 'not persisted' do
    its(:id) { should be_nil }
    it { should_not be_persisted }

    context 'with added id' do
      before(:each) { persistable.id = :test_id }

      its(:id) { should eq(:test_id) }
      it { should be_persisted }
    end
  end

  context 'persisted' do
    let(:initial_attrs) { {id: :test_id} }

    its(:id) { should eq(:test_id) }
    it { should be_persisted }

    it 'should not allow id change' do
      expect {
        persistable.id = :another_test_id
      }.to raise_error(Persistable::AlreadyPersistedError)

      expect {
        persistable.id = persisted.id
      }.to_not raise_error(Persistable::AlreadyPersistedError)
    end

    context 'with removed id' do
      before(:each) { persistable.id = nil }
      it { should_not be_persisted }
    end
  end

  let(:persistable_class) do
    Class.new(base_class) do
      include Persistable
    end
  end

  let(:base_class) do
    Class.new do
      def initialize *attrs
        initial_attrs(*attrs)
      end
    end
  end

  before(:each) do
    base_class.any_instance.tap do |b|
      b.should_receive(:initial_attrs).with(initial_attrs)
    end
  end
end
