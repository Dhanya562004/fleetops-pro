random = Random.new(20_261_016)
seed_password = ENV.fetch("DEMO_PASSWORD", "FleetOpsDemo2026!")

lot_data = [
  [ "Bengaluru Central", "Bengaluru" ], [ "Mumbai East", "Mumbai" ], [ "Pune Yard", "Pune" ],
  [ "Delhi NCR Hub", "New Delhi" ], [ "Hyderabad South", "Hyderabad" ], [ "Chennai Port", "Chennai" ]
]
lots = lot_data.map do |name, city|
  Lot.find_or_create_by!(name:) { |lot| lot.city = city; lot.capacity = 54 }
end

admin = User.find_or_create_by!(email: "admin@fleetops.local") do |user|
  user.name = "Asha Kulkarni"
  user.role = "admin"
  user.password = seed_password
end
ops_manager = User.find_or_create_by!(email: "ops@fleetops.local") do |user|
  user.name = "Kavya Rao"
  user.role = "ops_manager"
  user.password = seed_password
end
technicians = 60.times.map do |index|
  User.find_or_create_by!(email: "technician#{index + 1}@fleetops.local") do |user|
    user.name = [ "Rohan Menon", "Meera Nair", "Arjun Das", "Ishita Shah", "Kabir Joshi", "Ananya Iyer" ][index % 6] + " #{index + 1}"
    user.role = "technician"
    user.specialty = [ "Electrical", "Engine", "Bodywork", "Inspection", "Diagnostics" ][index % 5]
    user.password = seed_password
  end
end

supplier_names = [ "Metroline Components", "Western Auto Supply", "Deccan Parts Co", "Southern Spares", "Northstar Mobility" ]
suppliers = supplier_names.map do |name|
  Supplier.find_or_create_by!(name:) do |supplier|
    supplier.contact_email = "orders@#{name.downcase.gsub(/[^a-z]/, '')}.example"
    supplier.lead_time_note = "Fictional supplier / 3-7 business days"
  end
end

part_names = [ "Brake pad set", "Oil filter", "Air filter", "Clutch plate", "Coolant hose", "Headlamp assembly", "Alternator belt", "Wheel bearing", "Cabin filter", "Spark plug set", "Mirror assembly", "Battery 12V", "Shock absorber", "Wiper motor", "Radiator fan" ]
parts = 150.times.map do |index|
  sku = "FOP-P#{(index + 1).to_s.rjust(4, '0')}"
  Part.find_or_create_by!(sku:) do |part|
    part.name = "#{part_names[index % part_names.length]} / #{%w[compact sedan crossover hatchback][index % 4]}"
    part.supplier = suppliers[index % suppliers.length]
    part.stock_quantity = index % 13 == 0 ? 0 : random.rand(4..42)
    part.reorder_threshold = random.rand(5..12)
    part.unit_cost = random.rand(450..18_000)
  end
end

make_models = {
  "Maruti Suzuki" => %w[Baleno Brezza Swift Dzire Ertiga],
  "Tata" => %w[Nexon Punch Altroz Tiago Harrier],
  "Mahindra" => %w[XUV300 Thar Scorpio Bolero XUV700],
  "Hyundai" => %w[i20 Creta Venue Verna Exter],
  "Honda" => %w[City Amaze Elevate Jazz],
  "Toyota" => %w[Innova Glanza UrbanCruiser Camry]
}
vehicle_statuses = %w[ready ready ready ready inspection_pending in_repair awaiting_parts out_of_service in_transit]
vehicles = 300.times.map do |index|
  vin = "FOPIN#{(index + 1).to_s.rjust(12, '0')}"
  Vehicle.find_or_create_by!(vin:) do |vehicle|
    make = make_models.keys[index % make_models.length]
    vehicle.make = make
    vehicle.model = make_models.fetch(make)[index % make_models.fetch(make).length]
    vehicle.year = random.rand(2020..2025)
    vehicle.status = vehicle_statuses.sample(random:)
    vehicle.lot = lots[index % lots.length]
    vehicle.mileage = random.rand(2_000..96_000)
    vehicle.last_inspected_at = random.rand(1..120).days.ago
  end
end

ticket_statuses = %w[inspection repair quality_check awaiting_parts ready cancelled]
ticket_sequences = {
  "inspection" => %w[inspection], "repair" => %w[inspection repair],
  "quality_check" => %w[inspection repair quality_check],
  "awaiting_parts" => %w[inspection repair awaiting_parts],
  "ready" => %w[inspection repair quality_check ready],
  "cancelled" => %w[inspection cancelled]
}
categories = %w[brakes electrical engine bodywork inspection tyres cooling]
priorities = %w[low normal normal high urgent]

800.times do |index|
  seed_key = "seed-ticket-#{index + 1}"
  MaintenanceTicket.find_or_create_by!(seed_key:) do |ticket|
    created_at = random.rand(1..90).days.ago
    ticket.vehicle = vehicles[index % vehicles.length]
    ticket.technician = technicians[index % technicians.length]
    ticket.title = [ "Scheduled inspection", "Brake vibration diagnosis", "Replace cabin filter", "Electrical fault check", "Cooling system repair", "Tyre and alignment check" ][index % 6]
    ticket.category = categories[index % categories.length]
    ticket.priority = priorities.sample(random:)
    ticket.status = ticket_statuses.sample(random:)
    ticket.estimated_hours = random.rand(1..8)
    ticket.started_at = created_at + 1.hour unless ticket.status == "inspection"
    if ticket.status == "ready"
      ticket.actual_hours = random.rand(1..10)
      ticket.completed_at = created_at + random.rand(2..24).hours
    end
    ticket.created_at = created_at
    ticket.updated_at = [ created_at, 2.hours.ago ].max
  end
  ticket = MaintenanceTicket.find_by!(seed_key:)
  sequence = ticket_sequences.fetch(ticket.status)
  sequence.each_with_index do |state, event_index|
    ticket.ticket_status_events.find_or_create_by!(from_status: state == sequence.first ? nil : sequence[event_index - 1], to_status: state) do |event|
      event.user = ops_manager
      event.note = "Seeded operational status history"
      event.created_at = ticket.created_at + event_index.hours
    end
  end
  if ticket.status == "awaiting_parts"
    shortage_parts = parts.select { |part| part.stock_quantity.zero? }
    selected_part = shortage_parts[index % shortage_parts.length] || parts[index % parts.length]
    ticket.ticket_parts.find_or_create_by!(part: selected_part) do |request|
      request.quantity_requested = 1
      request.quantity_fulfilled = 0
    end
  end
end

lot_data.each_index do |lot_index|
  vehicles.slice(lot_index * 50, 50).to_a.each do |vehicle|
    latest_ticket = vehicle.maintenance_tickets.order(created_at: :desc).first
    next unless latest_ticket

    mapped = { "inspection" => "inspection_pending", "repair" => "in_repair", "quality_check" => "quality_check", "awaiting_parts" => "awaiting_parts", "ready" => "ready" }
    vehicle.update_column(:status, mapped[latest_ticket.status]) if mapped.key?(latest_ticket.status)
  end
end

legacy_cases = [
  [ "duplicate-vin-row", "vehicle", "duplicate_vin", { vin: vehicles.first.vin, import_row_ids: [ "raw-441", "raw-442" ] } ],
  [ "stale-ticket-row", "maintenance_ticket", "stale_awaiting_parts", { ticket_id: "legacy-82", status: "awaiting_parts", updated_at: 35.days.ago.iso8601 } ],
  [ "orphan-lot-row", "vehicle", "unknown_lot_reference", { vin: "LEGACYUNKNOWNLOT01", lot_id: 99_999 } ],
  [ "negative-stock-row", "part", "negative_stock", { sku: "LEGACY-PART-7", stock_quantity: -4 } ]
]
legacy_cases.each do |external_id, entity_type, issue_code, raw_payload|
  LegacyImportRow.find_or_create_by!(external_id:) do |row|
    row.entity_type = entity_type
    row.issue_code = issue_code
    row.raw_payload = raw_payload
  end
end

puts "Seeded #{Vehicle.count} vehicles across #{Lot.count} lots, #{technicians.length} technicians, #{Part.count} parts, and #{MaintenanceTicket.count} maintenance tickets."
puts "Demo accounts: admin@fleetops.local, ops@fleetops.local, technician1@fleetops.local"
puts "Password for all demo accounts comes from DEMO_PASSWORD (default: FleetOpsDemo2026!)."
