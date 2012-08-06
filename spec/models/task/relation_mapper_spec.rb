require 'spec_helper'

describe Task::RelationMapper do


  class RelationDouble
    include Task::PersistenceMethods

    def fields
      @fields ||= {}
    end

  end

  let(:mapper) { described_class.new }

  let(:relation_removed_on) { 1.day.ago }
  let(:relation_added_on)   { 2.days.ago }
  let(:relation) do
    RelationDouble.new.tap do |relation|
      relation.stub added_on: relation_added_on,
        removed_on: relation_removed_on
    end
  end

  let(:relation_records) { Task::Records::CompositeRelation }
  def create_relation_record
    relation_records.create!
  end

  describe '#store' do
    context 'not persisted relation' do
      subject(:not_persisted_relation) { relation.tap{ |r| r.id = nil } }
      before(:each) { mapper.store not_persisted_relation }

      its(:id) { should_not be_nil }
    end

    context 'persisted relation' do
      let(:record_id) { create_relation_record.id }
      subject(:persisted_relation) { relation.tap{ |r| r.id = record_id } }
      before(:each) { mapper.store persisted_relation }

      its(:id) { should eq(record_id) }
    end

    describe 'relation fields' do
      before(:each) do
        mapper.store relation
        @relation_record = relation_records.find(relation.id)
      end
      subject(:relation_record) { @relation_record }

      it { should_not be_nil }
      its(:added_on) { should eq_up_to_sec(relation_added_on) }
      its(:removed_on) { should eq_up_to_sec(relation_removed_on) }
    end

  end

end
