require 'lib/spec_helper'

require 'models/task'
require 'models/task/attributes/computed/task_methods'

describe 'Task with computed attributes' do
  subject(:task) { class_with_computed_attributes.new initial_attrs }

  describe '.computed_attributes' do
    before do
      class_with_computed_attributes.instance_eval do
        has_computed_attribute :attr, computed_from: {} { nil }
      end
    end
    its('class.computed_attributes') { should eq([:attr]) }
  end

  let(:beginning) { Time.zone.parse '2012-01-01' }
  let(:date1)     { Time.zone.parse '2012-01-03' }
  let(:date2)     { Time.zone.parse '2012-01-04' }
  let(:date3)     { Time.zone.parse '2012-01-05' }
  let(:ending)    { Time.zone.parse '2012-01-07' }
  let(:given_interval)   { TimeInterval.new beginning, ending }


  describe 'computed attribute revisions' do
    context 'for attribute that depends only on this task' do
      before do
        task.stub_editable_attr_rev_before given_interval.beginning, [{
          :for    => :other_attribute1,
          :value  => 'irrelevant value'
        }, {
          :for    => :other_attribute2,
          :value  => 'attribute2 value0'
        }]

        task.stub_editable_attr_revs_in given_interval, :other_attribute1, [{
          :on    => date1,
          :value => 'attribute1 value1'
        }, {
          :on    => date3,
          :value => 'attribute1 value2'
        }]
        task.stub_editable_attr_revs_in given_interval, :other_attribute2, [{
          :on    => date2,
          :value => 'attribute2 value1'
        }]
      end

      before do
        attr_proc = stub_proc [
          ['attribute1 value1', 'attribute2 value0'], 'computed value1',
          ['attribute1 value1', 'attribute2 value1'], 'computed value2',
          ['attribute1 value2', 'attribute2 value1'], 'computed value3',
        ]
        class_with_computed_attributes.instance_eval do
          has_computed_attribute :attr,
            {computed_from: {self: [:other_attribute1, :other_attribute2]}},
            &attr_proc
        end
      end

      specify do
        task.should_have_computed_revisions_in given_interval, :attr, [{
          :on    => date1,
          :value => 'computed value1',
        }, {
          :on    => date2,
          :value => 'computed value2',
        }, {
          :on    => date3,
          :value => 'computed value3',
        }]
      end
    end
  end


  let(:class_with_computed_attributes) { Class.new(base_class) }
  before(:each) do
    class_with_computed_attributes.instance_eval do
      include Task::Attributes::Computed::TaskMethods
      define_method(:inspect) { '<task>' }
    end
  end


  let(:initial_attrs) { Hash.new }

  before(:each) do
    base_class.any_instance.tap do |b|
      b.should_receive(:initial_attrs).with(initial_attrs)
    end
  end


  let(:base_class) do
    example_group = self
    Class.new do
      define_method(:example_group) { example_group }

      def initialize *attrs
        initial_attrs *attrs
      end

      def stub_editable_attr_revs_in(interval, name, revs_attrs = [])
        rev_stubs = revs_attrs.map do |rev_attrs|
          stubbed_editable_attr_rev \
            name, rev_attrs.fetch(:value), rev_attrs.fetch(:on)
        end

        self.stub(:editable_attribute_revisions).
          with(for: name, in: interval).and_return(rev_stubs)
      end

      def stub_editable_attr_rev_before(date, revs_attrs = [])
        revs_attrs.each do |rev_attrs|
          name = rev_attrs.fetch(:for)
          rev_stub = stubbed_editable_attr_rev \
            name, rev_attrs.fetch(:value), 1.day.until(date)
          self.stub(:last_editable_attribute_revision).
            with(for: name, on: date).and_return(rev_stub)
        end
      end

      def should_have_computed_revisions_in(interval, name, revs_attrs = [])
        actual_revs = self.computed_attribute_revisions for: name, in: interval

        expected_revs = revs_attrs.map do |rev_attrs|
          create_computed_attr_rev name, \
            rev_attrs.fetch(:value), rev_attrs.fetch(:on)
        end

        actual_revs.should == expected_revs
      end

      def stubbed_editable_attr_rev(name, value, update_date)
        example_group.stub('Editable attribute revision',  \
          attribute_name: name, updated_value: value, updated_on: update_date)
      end

      def create_computed_attr_rev(name, value, update_date)
        Task::Attributes::Computed::Revision.new \
          attribute_name: name,
          updated_value: value,
          updated_on: update_date,
          owner: self
      end
    end
  end

  def stub_proc(func_map)
    func = stub
    func_map.each_slice(2) do |input, output|
      func.stub(:eval).with(*input).and_return(output)
    end
    Proc.new { |*args| func.eval *args }
  end
end
