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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161019190520) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "documents", id: :string, limit: 32, force: :cascade do |t|
    t.string   "local_id",   limit: 32, null: false
    t.string   "owner",      limit: 32, null: false
    t.string   "collection"
    t.jsonb    "content"
    t.string   "txn_id"
    t.string   "updated_by"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["id"], name: "index_documents_on_id", unique: true, using: :btree
  end

  create_table "transactions", force: :cascade do |t|
    t.string  "owner"
    t.string  "user"
    t.string  "status"
    t.string  "tag"
    t.string  "stash_directory"
    t.string  "files",           default: [],    array: true
    t.boolean "completed",       default: false
    t.index ["owner"], name: "index_transactions_on_owner", using: :btree
  end

end
