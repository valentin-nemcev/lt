# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130118091800) do

  create_table "task_attribute_revisions", :force => true do |t|
    t.integer  "task_id"
    t.integer  "sequence_number",  :null => false
    t.datetime "update_date"
    t.string   "attribute_name",   :null => false
    t.string   "updated_value"
    t.boolean  "computed",         :null => false
    t.datetime "next_update_date"
  end

  add_index "task_attribute_revisions", ["task_id"], :name => "index_task_attribute_revisions_on_task_id"

  create_table "task_relations", :force => true do |t|
    t.integer  "subtask_id"
    t.integer  "supertask_id"
    t.string   "type"
    t.datetime "addition_date"
    t.datetime "removal_date"
  end

  add_index "task_relations", ["subtask_id"], :name => "index_task_relations_on_subtask_id"
  add_index "task_relations", ["supertask_id"], :name => "index_task_relations_on_supertask_id"

  create_table "tasks", :force => true do |t|
    t.integer  "user_id"
    t.datetime "creation_date"
  end

  add_index "tasks", ["user_id"], :name => "index_tasks_on_user_id"

  create_table "ui_states", :force => true do |t|
    t.string  "component", :null => false
    t.integer "user_id",   :null => false
    t.text    "state"
  end

  add_index "ui_states", ["user_id", "component"], :name => "index_ui_states_on_user_id_and_component", :unique => true
  add_index "ui_states", ["user_id"], :name => "index_ui_states_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
