class CreateTaskRecords < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :user
      t.string :type
      t.datetime :created_on
      t.datetime :completed_on
    end
    add_index :tasks, :user_id
  end
end
