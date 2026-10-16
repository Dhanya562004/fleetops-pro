module Maintenance
  class Transition
    class InvalidTransition < StandardError; end

    TRANSITIONS = {
      "inspection" => %w[repair cancelled],
      "repair" => %w[quality_check awaiting_parts cancelled],
      "awaiting_parts" => %w[repair cancelled],
      "quality_check" => %w[repair ready cancelled]
    }.freeze

    VEHICLE_STATUS = {
      "inspection" => "inspection_pending",
      "repair" => "in_repair",
      "awaiting_parts" => "awaiting_parts",
      "quality_check" => "quality_check",
      "ready" => "ready"
    }.freeze

    def self.call(ticket:, to:, actor: nil, note: nil)
      new(ticket:, to:, actor:, note:).call
    end

    def initialize(ticket:, to:, actor:, note:)
      @ticket_id = ticket.id
      @to = to.to_s
      @actor = actor
      @note = note
    end

    def call
      MaintenanceTicket.transaction do
        ticket = MaintenanceTicket.lock.find(@ticket_id)
        from = ticket.status
        allowed = TRANSITIONS.fetch(from, [])
        raise InvalidTransition, "Cannot move ticket from #{from} to #{@to}" unless allowed.include?(@to)
        raise InvalidTransition, "Fulfill requested parts before quality check" if @to == "quality_check" && !ticket.parts_fulfilled?

        ticket.update!(
          status: @to,
          started_at: ticket.started_at || Time.current,
          completed_at: (@to == "ready" ? Time.current : nil)
        )
        ticket.vehicle.update!(status: VEHICLE_STATUS.fetch(@to, ticket.vehicle.status))
        ticket.ticket_status_events.create!(user: @actor, from_status: from, to_status: @to, note: @note)
        Rails.cache.delete("fleet_metrics:v1")
        ticket
      end
    end
  end
end
