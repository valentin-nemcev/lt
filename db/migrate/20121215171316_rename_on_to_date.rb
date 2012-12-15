class RenameOnToDate < ActiveRecord::Migration
  def change
    rename_column :task_relations, :added_on, :addition_date
    rename_column :task_relations, :removed_on, :removal_date
    rename_column :tasks, :created_on, :creation_date
    rename_column :task_attribute_revisions, :updated_on, :update_date
  end
end
