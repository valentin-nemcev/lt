class RemoveQuotes < ActiveRecord::Migration
  def up
    drop_table :quotes
  end

  def down
    create_table "quotes" do |t|
      t.text     "content",    :null => false
      t.string   "source",     :null => false
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
      t.integer  "user_id"
    end
  end
end
