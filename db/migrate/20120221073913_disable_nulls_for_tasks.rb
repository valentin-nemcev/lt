class DisableNullsForTasks < ActiveRecord::Migration
  def set_nulls_to flag
    {
      :body  => :text,
      :lft   => :integer,
      :rgt   => :integer,
      :done  => :boolean
    }.each do |col, type|
      change_column :tasks, col, type, :null => flag
    end
  end

  def up
    set_nulls_to false
  end

  def down
    set_nulls_to true
  end
end
