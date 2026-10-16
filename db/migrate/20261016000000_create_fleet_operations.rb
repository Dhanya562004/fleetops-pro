class CreateFleetOperations < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "ops_manager"
      t.string :specialty
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_check_constraint :users, "role IN ('admin', 'ops_manager', 'technician')", name: "users_role_allowed"

    create_table :lots do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.string :region, null: false, default: "India"
      t.integer :capacity, null: false
      t.timestamps
    end
    add_index :lots, :name, unique: true
    add_check_constraint :lots, "capacity > 0", name: "lots_capacity_positive"

    create_table :vehicles do |t|
      t.string :vin, null: false
      t.string :make, null: false
      t.string :model, null: false
      t.integer :year, null: false
      t.string :status, null: false, default: "ready"
      t.references :lot, foreign_key: true
      t.integer :mileage, null: false, default: 0
      t.datetime :last_inspected_at
      t.timestamps
    end
    add_index :vehicles, :vin, unique: true
    add_index :vehicles, %i[status lot_id]
    add_check_constraint :vehicles, "status IN ('inspection_pending', 'in_repair', 'awaiting_parts', 'quality_check', 'ready', 'out_of_service', 'in_transit')", name: "vehicles_status_allowed"
    add_check_constraint :vehicles, "mileage >= 0", name: "vehicles_mileage_nonnegative"
    add_check_constraint :vehicles, "year BETWEEN 2000 AND 2100", name: "vehicles_year_valid"

    create_table :moves do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :from_lot, foreign_key: { to_table: :lots }
      t.references :to_lot, null: false, foreign_key: { to_table: :lots }
      t.references :moved_by, foreign_key: { to_table: :users }
      t.string :reason, null: false
      t.datetime :moved_at, null: false
      t.timestamps
    end
    add_index :moves, %i[vehicle_id moved_at]
    add_check_constraint :moves, "from_lot_id IS NULL OR from_lot_id <> to_lot_id", name: "moves_lots_must_differ"

    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_email
      t.string :lead_time_note
      t.timestamps
    end
    add_index :suppliers, :name, unique: true

    create_table :parts do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.references :supplier, null: false, foreign_key: true
      t.integer :stock_quantity, null: false, default: 0
      t.integer :reorder_threshold, null: false, default: 0
      t.decimal :unit_cost, precision: 10, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :parts, :sku, unique: true
    add_index :parts, %i[stock_quantity reorder_threshold]
    add_check_constraint :parts, "stock_quantity >= 0", name: "parts_stock_nonnegative"
    add_check_constraint :parts, "reorder_threshold >= 0", name: "parts_threshold_nonnegative"
    add_check_constraint :parts, "unit_cost >= 0", name: "parts_cost_nonnegative"

    create_table :maintenance_tickets do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :technician, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.string :category, null: false
      t.string :priority, null: false, default: "normal"
      t.string :status, null: false, default: "inspection"
      t.decimal :estimated_hours, precision: 6, scale: 2, null: false, default: 0
      t.decimal :actual_hours, precision: 6, scale: 2
      t.datetime :started_at
      t.datetime :completed_at
      t.string :seed_key
      t.timestamps
    end
    add_index :maintenance_tickets, :seed_key, unique: true
    add_index :maintenance_tickets, %i[status priority]
    add_index :maintenance_tickets, %i[technician_id status]
    add_index :maintenance_tickets, %i[vehicle_id status]
    add_check_constraint :maintenance_tickets, "status IN ('inspection', 'repair', 'quality_check', 'awaiting_parts', 'ready', 'cancelled')", name: "tickets_status_allowed"
    add_check_constraint :maintenance_tickets, "priority IN ('low', 'normal', 'high', 'urgent')", name: "tickets_priority_allowed"
    add_check_constraint :maintenance_tickets, "estimated_hours >= 0 AND (actual_hours IS NULL OR actual_hours >= 0)", name: "tickets_hours_nonnegative"

    create_table :ticket_parts do |t|
      t.references :maintenance_ticket, null: false, foreign_key: true
      t.references :part, null: false, foreign_key: true
      t.integer :quantity_requested, null: false
      t.integer :quantity_fulfilled, null: false, default: 0
      t.timestamps
    end
    add_index :ticket_parts, %i[maintenance_ticket_id part_id], unique: true
    add_check_constraint :ticket_parts, "quantity_requested > 0 AND quantity_fulfilled >= 0 AND quantity_fulfilled <= quantity_requested", name: "ticket_parts_quantities_valid"

    create_table :ticket_comments do |t|
      t.references :maintenance_ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
    add_index :ticket_comments, %i[maintenance_ticket_id created_at]

    create_table :ticket_status_events do |t|
      t.references :maintenance_ticket, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.text :note
      t.timestamps
    end
    add_index :ticket_status_events, %i[maintenance_ticket_id created_at]

    create_table :analytics_snapshots do |t|
      t.date :snapshot_date, null: false
      t.jsonb :metrics, null: false, default: {}
      t.timestamps
    end
    add_index :analytics_snapshots, :snapshot_date, unique: true

    create_table :legacy_import_rows do |t|
      t.string :entity_type, null: false
      t.string :external_id, null: false
      t.jsonb :raw_payload, null: false, default: {}
      t.string :issue_code, null: false
      t.datetime :processed_at
      t.timestamps
    end
    add_index :legacy_import_rows, %i[entity_type issue_code processed_at]
    add_index :legacy_import_rows, %i[entity_type external_id]

    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :topic, null: false
      t.string :idempotency_key, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at
      t.timestamps
    end
    add_index :notifications, :idempotency_key, unique: true
    add_index :notifications, %i[recipient_id processed_at]
  end
end
