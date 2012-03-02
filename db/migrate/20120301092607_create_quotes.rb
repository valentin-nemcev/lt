class CreateQuotes < ActiveRecord::Migration
  def change
    create_table :quotes do |t|
      t.text :content, :null => false
      t.string :source, :null => false

      t.timestamps
    end
  end
end
