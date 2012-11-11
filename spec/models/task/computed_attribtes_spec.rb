require 'lib/spec_helper'

require 'persistable'
require 'models/task'
require 'models/task/computed_attributes'

describe 'Task with computed attributes' do
  let(:class_with_computed_attributes) { Class.new(base_class) }
  before(:each) do
    class_with_computed_attributes.instance_eval do
      include Task::ComputedAttributes
      has_computed_attribute :attr, computed_from: {relation: :relation_attr}
      define_method(:inspect) { '<task>' }
    end
  end

  let(:initial_attrs) { Hash.new }
  subject(:task) { class_with_computed_attributes.new initial_attrs }

  describe '#computed_attribute_revisions', :pending do
    let(:crev1) { Task::AttributeRevision.new }
    let(:crev2) { Task::AttributeRevision.new }
    let(:attr_rev1) { Task::AttributeRevision.new }
    let(:attr_rev2) { Task::AttributeRevision.new }
    let(:given_period) { stub(:effective_date) }

    before do
      task.stub(:attribute_revisions)
        .with(:attr, given_period).and_return([attr_rev1, attr_rev2])
    end

    it 'returns a list of computed attribute revisions after given date' do
      task.computed_attribute_revisions(effective_date).should \
        == [crev1, crev2]
    end
  end

  let(:base_class) do
    Class.new do
      def initialize *attrs
        initial_attrs *attrs
      end
    end
  end

  before(:each) do
    base_class.any_instance.tap do |b|
      b.should_receive(:initial_attrs).with(initial_attrs)
      b.stub(created_on: created_on)
    end
  end

  let(:created_on)     { 'creation date' }
end
