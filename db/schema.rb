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

ActiveRecord::Schema[8.1].define(version: 2026_01_20_204026) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "ancestry"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_categories_on_ancestry"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "concepts", force: :cascade do |t|
    t.jsonb "body", default: {}, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["category_id"], name: "index_concepts_on_category_id"
    t.index ["created_at"], name: "index_concepts_on_created_at"
    t.index ["user_id"], name: "index_concepts_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "concept_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["concept_id"], name: "index_likes_on_concept_id"
    t.index ["user_id", "concept_id"], name: "index_likes_on_user_id_and_concept_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "pins", force: :cascade do |t|
    t.bigint "concept_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["concept_id"], name: "index_pins_on_concept_id"
    t.index ["created_at"], name: "index_pins_on_created_at"
    t.index ["user_id", "concept_id"], name: "index_pins_on_user_id_and_concept_id", unique: true
    t.index ["user_id"], name: "index_pins_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "allow_password_change", default: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "daily_concepts_count", default: 0, null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "image"
    t.boolean "is_subscribed", default: false, null: false
    t.datetime "last_concept_generated_at"
    t.datetime "last_subscribed_at"
    t.datetime "last_unsubscribed_at"
    t.string "name"
    t.string "nickname"
    t.string "provider", default: "email", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "timezone", default: "UTC", null: false
    t.json "tokens"
    t.string "uid", default: "", null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_subscribed"], name: "index_users_on_is_subscribed"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "concepts", "categories"
  add_foreign_key "concepts", "users", on_delete: :nullify
  add_foreign_key "likes", "concepts"
  add_foreign_key "likes", "users"
  add_foreign_key "pins", "concepts"
  add_foreign_key "pins", "users"
end
