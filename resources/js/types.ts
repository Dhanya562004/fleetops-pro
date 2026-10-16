export type User = { id: number; name: string; email: string; role: 'admin' | 'ops_manager' | 'technician' }
export type Lot = { id: number; name: string; city: string; capacity: number; occupancy?: number; occupancy_percent?: number; at_capacity?: boolean }
export type Vehicle = {
  id: number; vin: string; make: string; model: string; year: number; status: string; mileage: number
  lot?: Lot | null; lot_id?: number | null
}
export type TicketPartRequest = { id: number; part: { id: number; sku: string; name: string; stock_quantity: number }; quantity_requested: number; quantity_fulfilled: number }
export type Ticket = {
  id: number; title: string; status: string; priority: string; category: string; updated_at: string
  vehicle: Vehicle; technician?: User | null; estimated_hours: number; actual_hours?: number | null
  ticket_parts?: TicketPartRequest[]
}
export type SharedProps = { currentUser: User | null; flash: Record<string, string> }
