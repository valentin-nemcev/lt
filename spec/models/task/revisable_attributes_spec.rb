
require 'lib/spec_helper'

require 'persistable'
require 'models/task'
require 'models/task/revisable_attributes'


describe 'Object with revisable attributes' do
  let(:class_with_revisable_attributes) { Class.new(base_class) }
  before(:each) do
    stub_const('AttrNameRevision', stub())
    class_with_revisable_attributes.instance_eval do
      include Task::RevisableAttributes
      has_revisable_attribute :attr_name, :revision_class => AttrNameRevision
    end
  end

  #TODO: Specs for updating non-existing attributes
  #TODO: Specs for updates that doesn't change anything

  let(:initial_attrs) { Hash.new }
  subject { class_with_revisable_attributes.new initial_attrs }

  its('class.revisable_attributes') { should eq([:attr_name]) }
  its(:attribute_revisions) { should eq(attr_name: attr_revisions) }

  describe '#initialize' do
    context 'with attribute value passed' do
      let(:initial_attrs) { {:attr_name => :attr_value} }

      specify do
        attr_revisions.should_receive(:new_revision)
          .with(:attr_name => :attr_value, updated_on: effective_date)
        subject
      end
    end

    context 'with attribute revisions passed' do
      let(:initial_attrs) { {:attr_name_revisions => [attr_revision]} }

      specify do
        attr_revisions.should_receive(:set_revisions).with([attr_revision])
        subject
      end
    end

    context 'without attribute or revisions passed' do
      specify do
        attr_revisions.stub empty?: true
        expect{ subject }.to raise_error Task::MissingAttributeError
      end
    end
  end

  describe '#update_attributes' do
    specify do
      attr_revisions.should_receive(:new_revision)
        .with(:attr_name => :new_attr_value, updated_on: effective_date)
      subject.update_attributes :attr_name => :new_attr_value
    end
  end

  describe '#attr_name' do
    before(:each) do
      attr_revisions.should_receive(:last).and_return(attr_revision)
    end
    its(:attr_name) { should eq(:attr_value) }
  end


  before(:each) do
    stub_const('Revisions::Sequence', stub())

    Revisions::Sequence.should_receive(:new)
      .with(created_on: created_on, revision_class: AttrNameRevision)
      .and_return(attr_revisions)
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
      b.stub(created_on: created_on)
      b.stub(effective_date: effective_date)
    end
  end

  let(:created_on)     { 'creation date' }
  let(:effective_date) { 'effective date' }
  let(:attr_revisions) { stub(:attr_revision_sequence, empty?: false) }
  let(:attr_revision)  { stub(:attr_revision, attr_name: :attr_value) }
end
