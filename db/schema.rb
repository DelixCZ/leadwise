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

ActiveRecord::Schema[8.1].define(version: 2026_08_24_190000) do
  create_table "leads", force: :cascade do |t|
    t.text "ai_analysis"
    t.text "ai_objection"
    t.integer "ai_score"
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.text "evaluation_prompt"
    t.datetime "updated_at", null: false
    t.string "website", null: false
    t.check_constraint "ai_score IS NULL OR (ai_score BETWEEN 1 AND 100)", name: "leads_ai_score_range"
  end

  create_table "settings", force: :cascade do |t|
    t.text "company_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
