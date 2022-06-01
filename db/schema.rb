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



ActiveRecord::Schema.define(version: 20180904184901) do

  adapter_name = ActiveRecord::Base.connection.adapter_name.downcase

  autoinc_type = case adapter_name
                 when /^postgres/
                   :serial
                 when /^sqlite/
                   :integer
                 else
                   :integer
                 end

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  warn(extensions.to_s)

  create_table "documents", id: :string, limit: 32, force: :cascade do |t|
    t.string "local_id", limit: 32, null: false
    t.string "owner", limit: 32, null: false
    if adapter_name.starts_with?('postgres')
       t.jsonb "content"
    elsif adapter_name.starts_with?('sqlite')
      t.text "content"
    else
       t.text "content"
    end
    t.integer "txn_id"
    t.string "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted", default: false
    t.index ["id"], name: "index_documents_on_id", unique: true
    t.index ["txn_id"], name: "index_documents_on_txn_id"
  end

  create_table "transactions", id: autoinc_type, force: :cascade do |t|
    t.string "owner"
    t.string "status"
    t.string "tag"
    t.string "stash_directory"
    t.string "files", default: [].to_yaml, array: true
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["owner"], name: "index_transactions_on_owner"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    if adapter_name.starts_with?('postgres') 
      t.inet "current_sign_in_ip"
      t.inet "last_sign_in_ip"
    else
      t.string "current_sign_in_ip"
      t.string "last_sign_in_ip"
    end
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.boolean "approved", default: false, null: false
    t.string "authentication_token", limit: 30
    t.string "primary_institution"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "transactions", "users"
end
