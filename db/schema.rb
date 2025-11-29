# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_15_175350) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["room_id"], name: "index_entries_on_room_id"
    t.index ["user_id", "room_id"], name: "index_entries_on_user_id_and_room_id", unique: true
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "entry_sheet_item_templates", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "tag", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "tag"], name: "index_entry_sheet_item_templates_on_user_id_and_tag"
    t.index ["user_id"], name: "index_entry_sheet_item_templates_on_user_id"
  end

  create_table "entry_sheet_items", force: :cascade do |t|
    t.integer "char_limit"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "entry_sheet_id", null: false
    t.bigint "entry_sheet_item_template_id"
    t.integer "position", default: 0
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_sheet_id", "position"], name: "index_entry_sheet_items_on_entry_sheet_id_and_position"
    t.index ["entry_sheet_id"], name: "index_entry_sheet_items_on_entry_sheet_id"
    t.index ["entry_sheet_item_template_id"], name: "index_entry_sheet_items_on_entry_sheet_item_template_id"
  end

  create_table "entry_sheets", force: :cascade do |t|
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.datetime "deadline"
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deadline"], name: "index_entry_sheets_on_deadline"
    t.index ["user_id", "company_name"], name: "index_entry_sheets_on_user_id_and_company_name"
    t.index ["user_id", "status"], name: "index_entry_sheets_on_user_id_and_status"
    t.index ["user_id"], name: "index_entry_sheets_on_user_id"
  end

  create_table "general_contents", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "job_hunting_contents", force: :cascade do |t|
    t.string "company_name", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "result", null: false
    t.integer "selection_stage", null: false
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_job_hunting_contents_on_company_name"
    t.index ["result"], name: "index_job_hunting_contents_on_result"
    t.index ["selection_stage"], name: "index_job_hunting_contents_on_selection_stage"
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["user_id", "post_id"], name: "index_likes_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["room_id"], name: "index_messages_on_room_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "post_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "tag_id"], name: "index_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "contentable_id", null: false
    t.string "contentable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["contentable_type", "contentable_id"], name: "index_posts_on_contentable"
    t.index ["parent_id"], name: "index_posts_on_parent_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "posts_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "favorite_language"
    t.integer "internship_count"
    t.string "name"
    t.text "personal_message"
    t.string "provider"
    t.datetime "remember_created_at"
    t.string "research_lab"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "entries", "rooms"
  add_foreign_key "entries", "users"
  add_foreign_key "entry_sheet_item_templates", "users"
  add_foreign_key "entry_sheet_items", "entry_sheet_item_templates"
  add_foreign_key "entry_sheet_items", "entry_sheets"
  add_foreign_key "entry_sheets", "users"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "users"
  add_foreign_key "messages", "rooms"
  add_foreign_key "messages", "users"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "posts", "posts", column: "parent_id"
  add_foreign_key "posts", "users"
end
