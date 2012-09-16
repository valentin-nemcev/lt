require 'lib/spec_helper'

require 'persistable'
require 'models/task'
require 'models/task/revisable_attributes'


describe 'Object with revisable attributes' do
  let(:class_with_revisable_attributes) { Class.new(base_class) }
  before(:each) do
    stub_const('AttrNameRevision1', stub())
    stub_const('AttrNameRevision2', stub())
    class_with_revisable_attributes.instance_eval do
      include Task::RevisableAttributes
      has_revisable_attribute :attr_name1, :revision_class => AttrNameRevision1
      has_revisable_attribute :attr_name2, :revision_class => AttrNameRevision2
      define_method(:inspect) { '<task>' }
    end
  end

  #TODO: Specs for updating non-existing attributes
  #TODO: Specs for updates that doesn't change anything

  let(:initial_attrs) { Hash.new }
  subject(:task) { class_with_revisable_attributes.new initial_attrs }

  its('class.revisable_attributes') { should eq([:attr_name1, :attr_name2]) }

  describe '.new_attribute_revision' do
    subject(:new_revision) do
      task.class.new_attribute_revision :attr_name1, attrs
    end
    before(:each) do
      AttrNameRevision1.should_receive(:new).with(attrs)
        .and_return(attr_revision)
    end
    let(:attrs) { stub(:attrs) }

    it { should eq(attr_revision) }
  end

  describe '#attribute_revisions' do
    before(:each) do
      attr_revisions1.stub(to_a: [:attr1_rev1])
      attr_revisions2.stub(to_a: [:attr2_rev1, :attr2_rev2])
    end

    its(:attribute_revisions) do
      should match_array([:attr1_rev1, :attr2_rev1, :attr2_rev2])
    end
  end

  describe '#initialize' do
    context 'with attribute value passed' do
      let(:initial_attrs) { {:attr_name1 => :attr_value} }

      example do
        attr_revisions1.should_receive(:new_revision) do |args|
          @new_task = args.delete(:owner)
          args.should eq(:updated_value => :attr_value,
                         updated_on: created_on)
          attr_revision
        end
        task.should eq(@new_task)
      end
    end

    context 'with attribute revisions passed' do
      let(:attr1_rev1) { stub(:attr1_rev1, attribute_name: :attr_name1) }
      let(:attr1_rev2) { stub(:attr1_rev2, attribute_name: :attr_name1) }
      let(:attr2_rev1) { stub(:attr2_rev1, attribute_name: :attr_name2) }
      let(:initial_attrs) { {
        attribute_revisions: [attr1_rev1, attr1_rev2, attr2_rev1]
      } }

      specify do
        attr_revisions1.should_receive(:set_revisions)
          .with([attr1_rev1, attr1_rev2])
        attr_revisions2.should_receive(:set_revisions)
          .with([attr2_rev1])
        [attr1_rev1, attr1_rev2, attr2_rev1].each do |r|
          r.should_receive(:"owner=") { |task| (@new_tasks ||= []) << task }
        end
        task
        @new_tasks.uniq.should eq([task])
      end
    end

    context 'without attribute or revisions passed' do
      specify do
        attr_revisions2.stub empty?: true
        expect{ task }.to raise_error Task::MissingAttributeError
      end
    end
  end

  describe '#update_attributes' do
    before(:each) do
      attr_revisions1.should_receive(:new_revision)
        .with(:updated_value => :new_attr_value1,
              updated_on: update_date,
              owner: task)
        .and_return(attr_revision)
      attr_revisions2.should_receive(:new_revision)
        .with(:updated_value => :new_attr_value2,
              updated_on: update_date,
              owner: task)
        .and_return(attr_revision)
    end
    example do
      attrs = {:attr_name1 => :new_attr_value1, :attr_name2 => :new_attr_value2}
      task.update_attributes(attrs, on: update_date)
    end

    let(:update) { stub('update') }
  end


  before(:each) do
    stub_const('Revisions::Sequence', stub())

    Revisions::Sequence.should_receive(:new)
      .with(created_on: created_on, revision_class: AttrNameRevision1)
      .and_return(attr_revisions1)
    Revisions::Sequence.should_receive(:new)
      .with(created_on: created_on, revision_class: AttrNameRevision2)
      .and_return(attr_revisions2)
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
  let(:update_date)    { 'update date' }
  let(:attr_revisions1) { stub(:attr_revision_sequence1, empty?: false) }
  let(:attr_revisions2) { stub(:attr_revision_sequence2, empty?: false) }
  let(:attr_revision)  { stub(:attr_revision, attr_name: :attr_value) }
end
