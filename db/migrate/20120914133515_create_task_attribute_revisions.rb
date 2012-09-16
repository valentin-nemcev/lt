class CreateTaskAttributeRevisions < ActiveRecord::Migration
  def up
    create_table 'task_attribute_revisions' do |t|
      t.references 'task'
      t.integer    'sequence_number', :null => false
      t.datetime   'updated_on'
      t.string     'attribute_name', null: false
      t.string     'updated_value'
    end
  end

  def down
    drop_table 'task_attribute_revisions'
  end
end
