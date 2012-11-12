require 'lib/spec_helper'

require 'models/task'
require 'models/task/computed_attributes'

describe 'Task with computed attributes' do
  def create_computed_attr_rev(name, value, update_date)
    Task::ComputedAttributeRevision.new \
      attribute_name: name,
      updated_value: value,
      updated_on: update_date,
      owner: task
  end

  def create_revisable_attr_rev(name, value, update_date)
    stub('Revisable attribute revision',  \
      attribute_name: name, updated_value: value, updated_on: update_date)
  end

  let(:class_with_computed_attributes) { Class.new(base_class) }
  before(:each) do
    class_with_computed_attributes.instance_eval do
      include Task::ComputedAttributes
      define_method(:inspect) { '<task>' }
    end
  end

  let(:initial_attrs) { Hash.new }
  subject(:task) { class_with_computed_attributes.new initial_attrs }

  let(:beginning_date) { Time.zone.parse '2012-01-01' }
  let(:date1)          { Time.zone.parse '2012-01-03' }
  let(:date2)          { Time.zone.parse '2012-01-04' }
  let(:date3)          { Time.zone.parse '2012-01-05' }
  let(:ending_date)    { Time.zone.parse '2012-01-07' }
  let(:given_period)   { TimePeriod.new beginning_date, ending_date }


  describe 'computed attribute revisions' do

    context 'for attribute that depends only on this task' do
      let(:attr1_rev0) { nil }
      let(:attr2_rev0) { create_revisable_attr_rev \
        :other_attribute2, 'attribute2_value0', 1.day.until(beginning_date) }
      let(:attr1_rev1) { create_revisable_attr_rev \
        :other_attribute1, 'attribute1_value1', date1 }
      let(:attr2_rev1) { create_revisable_attr_rev \
        :other_attribute2, 'attribute2_value1', date2 }
      let(:attr1_rev2) { create_revisable_attr_rev \
        :other_attribute1, 'attribute1_value2', date3 }
      # let(:attr2_rev2) { create_revisable_attr_rev 'attribute2_value2', date3 }
      before do
        task.stub(:attribute_revisions).
          with(:other_attribute1, given_period).
          and_return([attr1_rev1, attr1_rev2])
        task.stub(:last_attribute_revision).
          with(:other_attribute1, given_period.beginning).
          and_return(attr1_rev0)
        task.stub(:attribute_revisions).
          with(:other_attribute2, given_period).
          and_return([attr2_rev1])
        task.stub(:last_attribute_revision).
          with(:other_attribute2, given_period.beginning).
          and_return(attr2_rev0)
      end


      let(:crev1) { create_computed_attr_rev \
        :attr, 'computed_value1', date1 }
      let(:crev2) { create_computed_attr_rev \
        :attr, 'computed_value2', date2 }
      let(:crev3) { create_computed_attr_rev \
        :attr, 'computed_value3', date3 }

      before do
        attr_computer = stub
        attr_computer.should_receive(:compute).
          with('attribute1_value1', 'attribute2_value0').
          and_return('computed_value1')
        attr_computer.should_receive(:compute).
          with('attribute1_value1', 'attribute2_value1').
          and_return('computed_value2')
        attr_computer.should_receive(:compute).
          with('attribute1_value2', 'attribute2_value1').
          and_return('computed_value3')

        class_with_computed_attributes.instance_eval do
          has_computed_attribute :attr, \
            computed_from: {self: [:other_attribute1, :other_attribute2]} \
          do |*args|
            attr_computer.compute *args
          end
        end
      end

      it 'returns a list of computed attribute revisions in a given period' do
        task.computed_attribute_revisions(:attr, given_period).should \
          == [crev1, crev2, crev3]
      end
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
