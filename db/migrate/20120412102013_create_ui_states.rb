class CreateUIStates < ActiveRecord::Migration
  def change
    create_table :ui_states do |t|
      t.string :component, null: false
      t.references :user,    null: false
      t.text :state
    end
    add_index :ui_states, :user_id
    add_index :ui_states, [:user_id, :component], unique: true
  end
end
