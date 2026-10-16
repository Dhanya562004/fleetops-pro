module Lots
  class MoveVehicle
    class CapacityExceeded < StandardError; end
    class InvalidMove < StandardError; end

    def self.call(vehicle:, to_lot:, reason:, actor: nil)
      new(vehicle:, to_lot:, reason:, actor:).call
    end

    def initialize(vehicle:, to_lot:, reason:, actor:)
      @vehicle_id = vehicle.id
      @to_lot_id = to_lot.id
      @reason = reason
      @actor = actor
    end

    def call
      Move.transaction do
        vehicle = Vehicle.lock.find(@vehicle_id)
        lot_ids = [ vehicle.lot_id, @to_lot_id ].compact.uniq.sort
        lots = Lot.where(id: lot_ids).order(:id).lock.index_by(&:id)
        destination = lots.fetch(@to_lot_id)
        current_lot = lots[vehicle.lot_id]

        raise InvalidMove, "Vehicle is already at this lot" if current_lot == destination
        raise CapacityExceeded, "#{destination.name} is at capacity" if destination.vehicles.count >= destination.capacity

        Move.create!(
          vehicle:,
          from_lot: current_lot,
          to_lot: destination,
          moved_by: @actor,
          reason: @reason,
          moved_at: Time.current
        )
        vehicle.update!(lot: destination)
        expire_analytics
        vehicle
      end
    end

    private

    def expire_analytics
      Rails.cache.delete("fleet_metrics:v1")
    end
  end
end
