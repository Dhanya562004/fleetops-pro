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

ActiveRecord::Schema[8.1].define(version: 2026_10_16_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analytics_snapshots", force: :cascade do |t|
    t.date "snapshot_date", null: false
    t.jsonb "metrics", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["snapshot_date"], name: "index_analytics_snapshots_on_snapshot_date", unique: true
  end

  create_table "legacy_import_rows", force: :cascade do |t|
    t.string "entity_type", null: false
    t.string "external_id", null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.string "issue_code", null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type", "external_id"], name: "index_legacy_import_rows_on_entity_type_and_external_id"
    t.index ["entity_type", "issue_code", "processed_at"], name: "idx_on_entity_type_issue_code_processed_at_362d041506"
  end

  create_table "lots", force: :cascade do |t|
    t.string "name", null: false
    t.string "city", null: false
    t.string "region", default: "India", null: false
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_lots_on_name", unique: true
    t.check_constraint "capacity > 0", name: "lots_capacity_positive"
  end

  create_table "maintenance_tickets", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "technician_id"
    t.string "title", null: false
    t.string "category", null: false
    t.string "priority", default: "normal", null: false
    t.string "status", default: "inspection", null: false
    t.decimal "estimated_hours", precision: 6, scale: 2, default: "0.0", null: false
    t.decimal "actual_hours", precision: 6, scale: 2
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "seed_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seed_key"], name: "index_maintenance_tickets_on_seed_key", unique: true
    t.index ["status", "priority"], name: "index_maintenance_tickets_on_status_and_priority"
    t.index ["technician_id", "status"], name: "index_maintenance_tickets_on_technician_id_and_status"
    t.index ["technician_id"], name: "index_maintenance_tickets_on_technician_id"
    t.index ["vehicle_id", "status"], name: "index_maintenance_tickets_on_vehicle_id_and_status"
    t.index ["vehicle_id"], name: "index_maintenance_tickets_on_vehicle_id"
    t.check_constraint "estimated_hours >= 0::numeric AND (actual_hours IS NULL OR actual_hours >= 0::numeric)", name: "tickets_hours_nonnegative"
    t.check_constraint "priority::text = ANY (ARRAY['low'::character varying, 'normal'::character varying, 'high'::character varying, 'urgent'::character varying]::text[])", name: "tickets_priority_allowed"
    t.check_constraint "status::text = ANY (ARRAY['inspection'::character varying, 'repair'::character varying, 'quality_check'::character varying, 'awaiting_parts'::character varying, 'ready'::character varying, 'cancelled'::character varying]::text[])", name: "tickets_status_allowed"
  end

  create_table "moves", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "from_lot_id"
    t.bigint "to_lot_id", null: false
    t.bigint "moved_by_id"
    t.string "reason", null: false
    t.datetime "moved_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_lot_id"], name: "index_moves_on_from_lot_id"
    t.index ["moved_by_id"], name: "index_moves_on_moved_by_id"
    t.index ["to_lot_id"], name: "index_moves_on_to_lot_id"
    t.index ["vehicle_id", "moved_at"], name: "index_moves_on_vehicle_id_and_moved_at"
    t.index ["vehicle_id"], name: "index_moves_on_vehicle_id"
    t.check_constraint "from_lot_id IS NULL OR from_lot_id <> to_lot_id", name: "moves_lots_must_differ"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.string "topic", null: false
    t.string "idempotency_key", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_notifications_on_idempotency_key", unique: true
    t.index ["recipient_id", "processed_at"], name: "index_notifications_on_recipient_id_and_processed_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.bigint "supplier_id", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.integer "reorder_threshold", default: 0, null: false
    t.decimal "unit_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_parts_on_sku", unique: true
    t.index ["stock_quantity", "reorder_threshold"], name: "index_parts_on_stock_quantity_and_reorder_threshold"
    t.index ["supplier_id"], name: "index_parts_on_supplier_id"
    t.check_constraint "reorder_threshold >= 0", name: "parts_threshold_nonnegative"
    t.check_constraint "stock_quantity >= 0", name: "parts_stock_nonnegative"
    t.check_constraint "unit_cost >= 0::numeric", name: "parts_cost_nonnegative"
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "idx_on_concurrency_key_priority_job_id_d4bdd8da1e"
    t.index ["expires_at", "concurrency_key"], name: "idx_on_expires_at_concurrency_key_c20fd0827b"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_on_queue_name_and_finished_at"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_on_scheduled_at_and_finished_at"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_ready_executions_on_priority_and_job_id"
    t.index ["queue_name", "priority", "job_id"], name: "idx_on_queue_name_priority_job_id_b116c992cd"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "idx_on_scheduled_at_priority_job_id_cf978ceebd"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_email"
    t.string "lead_time_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_suppliers_on_name", unique: true
  end

  create_table "ticket_comments", force: :cascade do |t|
    t.bigint "maintenance_ticket_id", null: false
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_ticket_id", "created_at"], name: "index_ticket_comments_on_maintenance_ticket_id_and_created_at"
    t.index ["maintenance_ticket_id"], name: "index_ticket_comments_on_maintenance_ticket_id"
    t.index ["user_id"], name: "index_ticket_comments_on_user_id"
  end

  create_table "ticket_parts", force: :cascade do |t|
    t.bigint "maintenance_ticket_id", null: false
    t.bigint "part_id", null: false
    t.integer "quantity_requested", null: false
    t.integer "quantity_fulfilled", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_ticket_id", "part_id"], name: "index_ticket_parts_on_maintenance_ticket_id_and_part_id", unique: true
    t.index ["maintenance_ticket_id"], name: "index_ticket_parts_on_maintenance_ticket_id"
    t.index ["part_id"], name: "index_ticket_parts_on_part_id"
    t.check_constraint "quantity_requested > 0 AND quantity_fulfilled >= 0 AND quantity_fulfilled <= quantity_requested", name: "ticket_parts_quantities_valid"
  end

  create_table "ticket_status_events", force: :cascade do |t|
    t.bigint "maintenance_ticket_id", null: false
    t.bigint "user_id"
    t.string "from_status"
    t.string "to_status", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["maintenance_ticket_id", "created_at"], name: "idx_on_maintenance_ticket_id_created_at_e818144c93"
    t.index ["maintenance_ticket_id"], name: "index_ticket_status_events_on_maintenance_ticket_id"
    t.index ["user_id"], name: "index_ticket_status_events_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "ops_manager", null: false
    t.string "specialty"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'ops_manager'::character varying, 'technician'::character varying]::text[])", name: "users_role_allowed"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "vin", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.integer "year", null: false
    t.string "status", default: "ready", null: false
    t.bigint "lot_id"
    t.integer "mileage", default: 0, null: false
    t.datetime "last_inspected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lot_id"], name: "index_vehicles_on_lot_id"
    t.index ["status", "lot_id"], name: "index_vehicles_on_status_and_lot_id"
    t.index ["vin"], name: "index_vehicles_on_vin", unique: true
    t.check_constraint "mileage >= 0", name: "vehicles_mileage_nonnegative"
    t.check_constraint "status::text = ANY (ARRAY['inspection_pending'::character varying, 'in_repair'::character varying, 'awaiting_parts'::character varying, 'quality_check'::character varying, 'ready'::character varying, 'out_of_service'::character varying, 'in_transit'::character varying]::text[])", name: "vehicles_status_allowed"
    t.check_constraint "year >= 2000 AND year <= 2100", name: "vehicles_year_valid"
  end

  add_foreign_key "maintenance_tickets", "users", column: "technician_id"
  add_foreign_key "maintenance_tickets", "vehicles"
  add_foreign_key "moves", "lots", column: "from_lot_id"
  add_foreign_key "moves", "lots", column: "to_lot_id"
  add_foreign_key "moves", "users", column: "moved_by_id"
  add_foreign_key "moves", "vehicles"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "parts", "suppliers"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "ticket_comments", "maintenance_tickets"
  add_foreign_key "ticket_comments", "users"
  add_foreign_key "ticket_parts", "maintenance_tickets"
  add_foreign_key "ticket_parts", "parts"
  add_foreign_key "ticket_status_events", "maintenance_tickets"
  add_foreign_key "ticket_status_events", "users"
  add_foreign_key "vehicles", "lots"
end
