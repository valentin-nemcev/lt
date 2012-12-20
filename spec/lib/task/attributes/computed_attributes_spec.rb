require 'lib/spec_helper'

require 'time_interval'
require 'task'
require 'task/attributes/computed/methods'

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
  let(:date4)     { Time.zone.parse '2012-01-06' }
  let(:ending)    { Time.zone.parse '2012-01-07' }

  describe 'last computed attribute revision' do
    let(:given_date) { beginning }

    before do
      task.stub_attr_rev_before given_date, [{
        :for    => :attr1,
        :value  => 'attr1 v'
      }]
      task.stub_editable_attr_rev_before given_date, [{
        :for    => :attr,
        :value  => 'attr v'
      }]

      related1_1, related1_2 =
        task.stub_last_related_tasks_before given_date, :relation1, 2

      task.stub_last_related_tasks_before given_date, :relation2, 0

      related1_1.stub_attr_rev_before given_date, [{
        :for    => :attr1_1,
        :value  => 'attr1_1_1 v'
      }, {
        :for    => :attr1_2,
        :value  => 'attr1_2_1 v'
      }]
      related1_2.stub_attr_rev_before given_date, [{
        :for    => :attr1_1,
        :value  => 'attr1_1_2 v'
      }, {
        :for    => :attr1_2,
        :value  => 'attr1_2_2 v'
      }]
    end

    before do
      attr_proc = stub_proc [
        ['attr1 v', 'attr v', ['attr1_1_1 v', 'attr1_1_2 v'],
                              ['attr1_2_1 v', 'attr1_2_2 v'], []],
        'computed v',
      ]
      class_with_computed_attributes.instance_eval do
        has_computed_attribute :attr,
          {computed_from: {
            self:      [:attr1, :attr],
            relation1: [:attr1_1, :attr1_2],
            relation2: [:attr2_1]
          }}, &attr_proc
      end
    end

    specify do
      task.should_have_last_computed_revision_before given_date, :attr, {
        :value => 'computed v'
      }
    end
  end

  describe 'computed attribute revisions' do
    let(:given_interval) { TimeInterval.new beginning, ending }

    context 'for attribute of newly created task' do
      # Timeline
      #       date:    b   1   2   3   4   e
      #      attr1: n--1--------------------
      #       attr: ---1--------------------

      before do
        task.stub_attr_rev_before given_interval.beginning, [{
          :for    => :attr1,
          :value  => nil
        }]

        task.stub_attr_revs_in given_interval, :attr1, [{
          :on    => given_interval.beginning,
          :value => 'attr1 value1'
        }]
      end

      before do
        attr_proc = stub_proc [
          [nil], nil,
          ['attr1 value1'], 'computed value1',
        ]
        class_with_computed_attributes.instance_eval do
          has_computed_attribute :attr,
            {computed_from: {self: [:attr1]}},
            &attr_proc
        end
      end

      specify do
        task.should_have_computed_revisions_in given_interval, :attr, [{
          :on    => given_interval.beginning,
          :value => 'computed value1',
        }]
      end
    end

    context 'for attribute that does not change' do
      # Timeline
      #       date:   b   1   2   3   4   e
      #      attr1: 0-----1---2---3--------
      #       attr: 0-----0---0---1--------

      before do
        task.stub_attr_rev_before given_interval.beginning, [{
          :for    => :attr1,
          :value  => 'attr1 value0'
        }]

        task.stub_attr_revs_in given_interval, :attr1, [{
          :on    => date1,
          :value => 'attr1 value1'
        }, {
          :on    => date2,
          :value => 'attr1 value2'
        }, {
          :on    => date3,
          :value => 'attr1 value3'
        }]
      end

      before do
        attr_proc = stub_proc [
          ['attr1 value0'], 'computed value0',
          ['attr1 value1'], 'computed value0',
          ['attr1 value2'], 'computed value0',
          ['attr1 value3'], 'computed value1',
        ]
        class_with_computed_attributes.instance_eval do
          has_computed_attribute :attr,
            {computed_from: {self: [:attr1]}},
            &attr_proc
        end
      end

      specify do
        task.should_have_computed_revisions_in given_interval, :attr, [{
          :on    => date3,
          :value => 'computed value1',
        }]
      end
    end

    context 'for attribute that depends on attributes of its own task' do
      # Timeline
      #       date:    b   1   2   3   4   e
      #      attr1: 0------1-------2--------
      #      attr2: 0----------1------------
      #     attr_e: 0--------------1---2----
      #       attr: 0------1---2---3---4----

      before do
        task.stub_attr_rev_before given_interval.beginning, [{
          :for    => :attr1,
          :value  => 'attr1 value0'
        }, {
          :for    => :attr2,
          :value  => 'attr2 value0'
        }]
        task.stub_editable_attr_rev_before given_interval.beginning, [{
          :for    => :attr,
          :value  => 'attr value0'
        }]

        task.stub_attr_revs_in given_interval, :attr1, [{
          :on    => date1,
          :value => 'attr1 value1'
        }, {
          :on    => date3,
          :value => 'attr1 value2'
        }]
        task.stub_attr_revs_in given_interval, :attr2, [{
          :on    => date2,
          :value => 'attr2 value1'
        }]
        task.stub_editable_attr_revs_in given_interval, :attr, [{
          :on    => date3,
          :value => 'attr value1'
        }, {
          :on    => date4,
          :value => 'attr value2'
        }]
      end

      before do
        attr_proc = stub_proc [
          ['attr1 value0', 'attr2 value0', 'attr value0'], 'computed value0',
          ['attr1 value1', 'attr2 value0', 'attr value0'], 'computed value1',
          ['attr1 value1', 'attr2 value1', 'attr value0'], 'computed value2',
          ['attr1 value2', 'attr2 value1', 'attr value1'], 'computed value3',
          ['attr1 value2', 'attr2 value1', 'attr value2'], 'computed value4',
        ]
        class_with_computed_attributes.instance_eval do
          has_computed_attribute :attr,
            {computed_from: {self: [:attr1, :attr2, :attr]}},
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
        }, {
          :on    => date4,
          :value => 'computed value4',
        }]
      end
    end

    context 'for attribute that depends on attributes of related tasks' do
      # Timeline
      #       date:   b   1   2   3   4   e
      # related1_1: ----------]              ← effective interval of relation
      #    attr1_1: 0---------               ← values of attribute revisions
      #    attr1_2: 0-1---2---
      # related2_1: ------------------]
      #    attr2_1: 0-----------------
      # related2_2:               [--------
      #    attr2_1:               1--------
      #       attr: --1---2---3---4---5----

      before do
        related1_1, *_ = task.stub_related_tasks_in given_interval,
          :relation1, [{
            addition_date:   1.day.until(given_interval.beginning),
            removal_date: date2,
          }]

        related1_1.stub_attr_rev_before given_interval.beginning, [{
          :for    => :attr1_1,
          :value  => 'attr1_1 v0'
        }, {
          :for    => :attr1_2,
          :value  => 'attr1_2 v0'
        }]
        related1_1.stub_attr_revs_in TimeInterval.new(beginning, date2),
          :attr1_2, [{
            :on    => given_interval.beginning,
            :value => 'attr1_2 v1'
          }, {
            :on    => date1,
            :value => 'attr1_2 v2'
          }]

        related2_1, related2_2 = task.stub_related_tasks_in given_interval,
          :relation2, [{
              addition_date:   1.day.until(given_interval.beginning),
              removal_date: date4,
            }, {
              addition_date:   date3,
              removal_date: 1.day.since(given_interval.ending),
            }]

        related2_1.stub_attr_rev_before given_interval.beginning, [{
          :for    => :attr2_1,
          :value  => 'attr2_1_1 v0'
        }]
        # related2_2.stub_attr_rev_before date3, [{
        #   :for    => :attr2_1,
        #   :value  => 'attr2_1_2 v0'
        # }]
        related2_2.stub_attr_revs_in TimeInterval.new(date3, ending),
          :attr2_1, [{
            :on    => date3,
            :value => 'attr2_1_2 v1'
          }]
      end

      before do
        attr_proc = stub_proc [
          [[], [], []],
          'computed v0',
          [['attr1_1 v0'], ['attr1_2 v1'], ['attr2_1_1 v0']],
          'computed v1',
          [['attr1_1 v0'], ['attr1_2 v2'], ['attr2_1_1 v0']],
          'computed v2',
          [[            ], [            ], ['attr2_1_1 v0']],
          'computed v3',
          [[            ], [            ], ['attr2_1_1 v0', 'attr2_1_2 v1']],
          'computed v4',
          [[            ], [            ], [                'attr2_1_2 v1']],
          'computed v5',
        ]
        class_with_computed_attributes.instance_eval do
          has_computed_attribute :attr,
            {computed_from: {
              relation1: [:attr1_1, :attr1_2],
              relation2: [:attr2_1]
            }}, &attr_proc
        end
      end
      specify do
        task.should_have_computed_revisions_in given_interval, :attr, [{
          :on    => given_interval.beginning,
          :value => 'computed v1',
        }, {
          :on    => date1,
          :value => 'computed v2',
        }, {
          :on    => date2,
          :value => 'computed v3',
        }, {
          :on    => date3,
          :value => 'computed v4',
        }, {
          :on    => date4,
          :value => 'computed v5',
        }]
      end
    end
  end


  let(:class_with_computed_attributes) { Class.new(base_class) }
  before(:each) do
    class_with_computed_attributes.instance_eval do
      include Task::Attributes::Computed::Methods
      define_method(:inspect) { '<task>' }
    end
  end


  let(:initial_attrs) { Hash.new }

  # before(:each) do
  #   base_class.any_instance.tap do |b|
  #     b.should_receive(:initial_attrs).with(initial_attrs).at_least(:once)
  #   end
  # end


  let(:base_class) do
    example_group = self
    Class.new do
      define_method(:example_group) { example_group }

      def initialize(*)
        self.stub(
          :last_attribute_revision => nil,
          :attribute_revisions => [],
          :last_related_tasks => [],
        )
      end

      def stub_editable_attr_revs_in(*args)
        stub_attr_revs_in(*args, true)
      end

      def stub_attr_revs_in(interval, name, revs_attrs = [], editable = false)
        rev_stubs = revs_attrs.map do |rev_attrs|
          stubbed_attr_rev \
            name, rev_attrs.fetch(:value), rev_attrs.fetch(:on)
        end

        method = editable ?
          :editable_attribute_revisions : :attribute_revisions
        self.stub(method).with(:for => name, :in => interval).and_return(rev_stubs)
      end

      def stub_editable_attr_rev_before(*args)
        stub_attr_rev_before(*args, true)
      end

      def stub_attr_rev_before(date, revs_attrs = [], editable = false)
        revs_attrs.each do |rev_attrs|
          name = rev_attrs.fetch(:for)
          rev_stub = stubbed_attr_rev \
            name, rev_attrs.fetch(:value), 1.day.until(date)
          method = editable ?
            :last_editable_attribute_revision : :last_attribute_revision
          self.stub(method).with(:for => name, before: date).and_return(rev_stub)
        end
      end

      def stub_related_tasks_in(interval, relation, rels_attrs = [])
        task_stubs = rels_attrs.map do |rel_attrs|
          task = self.class.new
          [task, TimeInterval.new(rel_attrs[:addition_date], rel_attrs[:removal_date])]
        end
        self.stub(:related_tasks).
          with(:for => relation, :in => interval).and_return(task_stubs)
        task_stubs.collect(&:first)
      end

      def stub_last_related_tasks_before(date, relation, rel_count)
        task_stubs = rel_count.times.map do
          task = self.class.new
          [task, nil]
        end
        self.stub(:last_related_tasks).
          with(:for => relation, before: date).and_return(task_stubs)
        task_stubs.collect(&:first)
      end

      def should_have_computed_revisions_in(interval, name, revs_attrs = [])
        actual_revs =
          self.computed_attribute_revisions :for => name, :in => interval

        expected_revs = revs_attrs.map do |rev_attrs|
          create_computed_attr_rev name, \
            rev_attrs.fetch(:value), rev_attrs.fetch(:on)
        end

        actual_revs.should == expected_revs
      end

      def should_have_last_computed_revision_before(date, name, rev_attrs = [])
        actual_rev =
          self.last_computed_attribute_revision :for => name, :before => date

        actual_rev.updated_value.should == rev_attrs.fetch(:value)
      end

      def stubbed_attr_rev(name, value, update_date)
        example_group.stub('Attribute revision',  \
          attribute_name: name, updated_value: value, update_date: update_date)
      end

      def create_computed_attr_rev(name, value, update_date)
        Task::Attributes::Computed::Revision.new \
          attribute_name: name,
          updated_value: value,
          update_date: update_date,
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
