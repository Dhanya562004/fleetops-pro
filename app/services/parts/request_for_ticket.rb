module Parts
  class RequestForTicket
    def self.call(ticket:, part:, quantity:, actor: nil)
      MaintenanceTicket.transaction do
        request = TicketPart.create!(
          maintenance_ticket: ticket,
          part:,
          quantity_requested: quantity,
          quantity_fulfilled: 0
        )

        if part.stock_quantity < quantity && ticket.status == "repair"
          Maintenance::Transition.call(ticket:, to: "awaiting_parts", actor:, note: "Waiting for #{part.name}")
        end
        request
      end
    end
  end
end
