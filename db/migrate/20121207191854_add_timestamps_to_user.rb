class AddTimestampsToUser < ActiveRecord::Migration
  def change
    change_table(:users) { |t| t.timestamps }
  end
end
