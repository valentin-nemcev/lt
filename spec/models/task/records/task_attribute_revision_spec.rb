require 'spec_helper'

class AttributeRevisionDouble
  include Persistable

  def initialize(*)
  end
end


describe Task::Records::TaskAttributeRevision do
  let(:revision_records) { described_class }

  let(:test_value) { 'Test value' }
  let(:updated_test_value) { 'Test value updated' }
  let(:test_update_date) { 4.days.ago }
  let(:test_sn) { 2 }

  let(:task_record) { Task::Records::Task.create! }
  let(:task) { stub('task') }

  describe '#save_revisions' do
    let(:attribute_revisions) do
      (1..3).map do |i|
        AttributeRevisionDouble.new.tap do |rev|
          rev.stub(
            attribute_name: :attr_name,
            updated_value: "Test value #{i}",
            update_date: test_update_date,
            sequence_number: i,
          )
        end
      end
    end

    it 'stores all revisions' do
      revision_records.save_revisions task_record, attribute_revisions
      expected_size = task_record.attribute_revisions.size
      attribute_revisions.size.should eq(expected_size)
    end
  end

  describe '#save_revision' do

    let(:attribute_revision) do
      AttributeRevisionDouble.new.tap do |rev|
        rev.stub(
          attribute_name: :attr_name,
          updated_value: test_value,
          update_date: test_update_date,
          sequence_number: test_sn,
        )
      end
    end

    context 'new revision' do

      subject(:revision_record) do
        revision_records.save_revision task_record, attribute_revision
      end

      it 'stores revision fields' do
        revision_record.id.should eq(attribute_revision.id)
        revision_record.updated_value.should eq(test_value)
        revision_record.attribute_name.should eq('attr_name')
        revision_record.update_date.should eq_up_to_sec(test_update_date)
      end
    end

    context 'existing revision' do

      before(:each) do
        revision_records.save_revision task_record, attribute_revision
        attribute_revision.stub(updated_value: updated_test_value)
        revision_records.save_revision task_record, attribute_revision
      end

      it 'stores updated fields' do
        revision_record = task_record.attribute_revisions
          .find(attribute_revision.id)
        revision_record.updated_value.should eq(updated_test_value)
      end
    end
  end

  describe '#load_revisions' do
    context 'multiple revisions' do
      before(:each) do
        (1..3).to_a.reverse.map do |i|
          task_record.attribute_revisions.create!(
            attribute_name: :attr_name,
            updated_value: "Test value #{i}",
            update_date: test_update_date,
            sequence_number: i,
          )
        end
        Task::Base.stub(new_attribute_revision: stub(:revision))
      end

      it 'fetched all revisions' do
        revisions = revision_records.load_revisions task_record
        revisions.size.should eq(3)
      end
    end

    it 'fetches revision fields' do
      revision_record = task_record.attribute_revisions.create! do |rec|
        rec.attribute_name = 'attr_name'
        rec.updated_value = test_value
        rec.update_date = test_update_date
        rec.sequence_number = test_sn
      end

      Task::Base.should_receive(:new_attribute_revision) do |name, attrs|
        name.should eq(:attr_name)
        attrs = OpenStruct.new attrs
        attrs.owner = task
        attrs.updated_value.should eq(test_value)
        attrs.update_date.should eq_up_to_sec(test_update_date)
        attrs.sequence_number.should eq(test_sn)
        attrs.id.should eq(revision_record.id)
      end
      revision_records.load_revisions(task_record).fetch 0
    end
  end
end
