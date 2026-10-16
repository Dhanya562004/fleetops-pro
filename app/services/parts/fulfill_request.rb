module Parts
  class FulfillRequest
    class InsufficientStock < StandardError; end

    def self.call(ticket_part:, quantity:, actor: nil)
      MaintenanceTicket.transaction do
        request = TicketPart.lock.find(ticket_part.id)
        part = Part.lock.find(request.part_id)
        remaining = request.quantity_requested - request.quantity_fulfilled
        raise ArgumentError, "Quantity must be positive and no greater than remaining" unless quantity.to_i.positive? && quantity.to_i <= remaining
        raise InsufficientStock, "Not enough stock for #{part.name}" if part.stock_quantity < quantity.to_i

        part.update!(stock_quantity: part.stock_quantity - quantity.to_i)
        request.update!(quantity_fulfilled: request.quantity_fulfilled + quantity.to_i)

        if request.maintenance_ticket.status == "awaiting_parts" && request.maintenance_ticket.parts_fulfilled?
          Maintenance::Transition.call(ticket: request.maintenance_ticket, to: "repair", actor:, note: "Requested parts fulfilled")
        end
        Rails.cache.delete("fleet_metrics:v1")
        request
      end
    end
  end
end
