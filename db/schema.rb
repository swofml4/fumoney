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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160821061301) do

  create_table "asset_types", force: :cascade do |t|
    t.string   "name",                      limit: 255
    t.decimal  "historical_std_deviation",              precision: 6, scale: 2
    t.decimal  "historical_average_return",             precision: 6, scale: 2
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
  end

  create_table "correlation_collections", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "correlations", force: :cascade do |t|
    t.decimal  "correlation_amount",                  precision: 6, scale: 2
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "correlation_collection_id", limit: 4
    t.integer  "asset_type1_id",            limit: 4
    t.integer  "asset_type2_id",            limit: 4
  end

  add_index "correlations", ["asset_type1_id"], name: "fk_rails_02cfdb185c", using: :btree
  add_index "correlations", ["asset_type2_id"], name: "fk_rails_f6127f20f4", using: :btree
  add_index "correlations", ["correlation_collection_id"], name: "index_correlations_on_correlation_collection_id", using: :btree

  create_table "path_assets", force: :cascade do |t|
    t.decimal  "starting_amount",                        precision: 12, scale: 2
    t.decimal  "return_amount",                          precision: 12, scale: 2
    t.decimal  "contributions_or_draw_amount",           precision: 12, scale: 2
    t.decimal  "rebalance_amount",                       precision: 12, scale: 2
    t.decimal  "ending_amount",                          precision: 12, scale: 2
    t.decimal  "return_rate",                            precision: 6,  scale: 2
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
    t.integer  "asset_type_id",                limit: 4
    t.integer  "path_portfolio_id",            limit: 4
  end

  add_index "path_assets", ["asset_type_id"], name: "index_path_assets_on_asset_type_id", using: :btree
  add_index "path_assets", ["path_portfolio_id"], name: "index_path_assets_on_path_portfolio_id", using: :btree

  create_table "path_portfolios", force: :cascade do |t|
    t.integer  "year",       limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "path_id",    limit: 4
  end

  add_index "path_portfolios", ["path_id"], name: "index_path_portfolios_on_path_id", using: :btree

  create_table "paths", force: :cascade do |t|
    t.string   "path_type",     limit: 255
    t.string   "path_title",    limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "simulation_id", limit: 4
  end

  add_index "paths", ["simulation_id"], name: "index_paths_on_simulation_id", using: :btree

  create_table "simulations", force: :cascade do |t|
    t.string   "title",                     limit: 255
    t.integer  "number_of_paths",           limit: 4
    t.integer  "starting_age",              limit: 4
    t.integer  "retirement_age",            limit: 4
    t.integer  "last_simulation_age",       limit: 4
    t.decimal  "annual_contribution",                   precision: 12, scale: 2
    t.decimal  "contribution_growth",                   precision: 6,  scale: 2
    t.decimal  "retirement_draw",                       precision: 12, scale: 2
    t.decimal  "retirement_draw_growth",                precision: 6,  scale: 2
    t.decimal  "risk_of_ruin",                          precision: 6,  scale: 2
    t.string   "simulation_status",         limit: 255
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.integer  "correlation_collection_id", limit: 4
    t.boolean  "rebalance_flag"
  end

  add_index "simulations", ["correlation_collection_id"], name: "index_simulations_on_correlation_collection_id", using: :btree

  create_table "starting_assets", force: :cascade do |t|
    t.decimal  "amount",                  precision: 12, scale: 2
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.integer  "simulation_id", limit: 4
    t.integer  "asset_type_id", limit: 4
  end

  add_index "starting_assets", ["asset_type_id"], name: "index_starting_assets_on_asset_type_id", using: :btree
  add_index "starting_assets", ["simulation_id"], name: "index_starting_assets_on_simulation_id", using: :btree

  create_table "target_allocations", force: :cascade do |t|
    t.decimal  "allocation",              precision: 6, scale: 2
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "simulation_id", limit: 4
    t.integer  "asset_type_id", limit: 4
  end

  add_index "target_allocations", ["asset_type_id"], name: "index_target_allocations_on_asset_type_id", using: :btree
  add_index "target_allocations", ["simulation_id"], name: "index_target_allocations_on_simulation_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "admin_flag",                         default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "correlations", "asset_types", column: "asset_type1_id"
  add_foreign_key "correlations", "asset_types", column: "asset_type2_id"
  add_foreign_key "correlations", "correlation_collections"
  add_foreign_key "path_assets", "asset_types"
  add_foreign_key "path_assets", "path_portfolios"
  add_foreign_key "path_portfolios", "paths"
  add_foreign_key "paths", "simulations"
  add_foreign_key "simulations", "correlation_collections"
  add_foreign_key "starting_assets", "asset_types"
  add_foreign_key "starting_assets", "simulations"
  add_foreign_key "target_allocations", "asset_types"
  add_foreign_key "target_allocations", "simulations"
end
