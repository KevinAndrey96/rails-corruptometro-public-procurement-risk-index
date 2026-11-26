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

ActiveRecord::Schema[8.1].define(version: 2026_11_26_060200) do
  create_table "contractors", force: :cascade do |t|
    t.string "name", limit: 150, null: false
    t.integer "document_type", null: false
    t.string "document_number", limit: 11, null: false
    t.date "incorporated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_type", "document_number"], name: "index_contractors_on_document_type_and_document_number", unique: true
  end

  create_table "contracts", force: :cascade do |t|
    t.integer "entity_id", null: false
    t.integer "contractor_id", null: false
    t.string "reference", limit: 60, null: false
    t.text "object", null: false
    t.integer "modality", null: false
    t.date "signed_on", null: false
    t.date "start_on"
    t.date "end_on"
    t.bigint "initial_value", null: false
    t.bigint "additions_value", default: 0, null: false
    t.integer "bidders_count"
    t.integer "risk_score", default: 0, null: false
    t.json "red_flags", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contractor_id"], name: "index_contracts_on_contractor_id"
    t.index ["entity_id", "reference"], name: "index_contracts_on_entity_id_and_reference", unique: true
    t.index ["entity_id"], name: "index_contracts_on_entity_id"
    t.index ["risk_score"], name: "index_contracts_on_risk_score"
    t.index ["signed_on"], name: "index_contracts_on_signed_on"
    t.check_constraint "additions_value >= 0", name: "contracts_additions_value_not_negative"
    t.check_constraint "bidders_count IS NULL OR bidders_count > 0", name: "contracts_bidders_count_positive"
    t.check_constraint "initial_value > 0", name: "contracts_initial_value_positive"
    t.check_constraint "risk_score BETWEEN 0 AND 100", name: "contracts_risk_score_range"
  end

  create_table "entities", force: :cascade do |t|
    t.string "name", limit: 150, null: false
    t.string "nit", limit: 11, null: false
    t.integer "level", null: false
    t.string "department", limit: 60, null: false
    t.integer "risk_index", default: 0, null: false
    t.bigint "contracted_value", default: 0, null: false
    t.integer "contracts_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nit"], name: "index_entities_on_nit", unique: true
    t.index ["risk_index"], name: "index_entities_on_risk_index"
    t.check_constraint "risk_index BETWEEN 0 AND 100", name: "entities_risk_index_range"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "contracts", "contractors"
  add_foreign_key "contracts", "entities"
  add_foreign_key "sessions", "users"
end
