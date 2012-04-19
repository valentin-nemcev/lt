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

ActiveRecord::Schema.define(:version => 20120416185942) do

  create_table "quotes", :force => true do |t|
    t.text     "content",    :null => false
    t.string   "source",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "user_id"
  end

  create_table "task_dependencies", :force => true do |t|
    t.integer "blocking_task_id",  :null => false
    t.integer "dependent_task_id", :null => false
    t.boolean "direct",            :null => false
    t.integer "count",             :null => false
  end

  create_table "tasks", :force => true do |t|
    t.text     "body",         :null => false
    t.integer  "parent_id"
    t.integer  "lft",          :null => false
    t.integer  "rgt",          :null => false
    t.integer  "depth"
    t.date     "deadline"
    t.datetime "created_at",   :null => false
    t.datetime "completed_at"
    t.integer  "user_id"
  end

  create_table "ui_states", :force => true do |t|
    t.string  "component", :null => false
    t.integer "user_id",   :null => false
    t.text    "state"
  end

  add_index "ui_states", ["user_id", "component"], :name => "index_ui_states_on_user_id_and_component", :unique => true
  add_index "ui_states", ["user_id"], :name => "index_ui_states_on_user_id"

  create_table "users", :force => true do |t|
    t.string "login"
    t.string "name"
  end

end
