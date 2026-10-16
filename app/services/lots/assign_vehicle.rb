module Lots
  class AssignVehicle
    class CapacityExceeded < StandardError; end

    def self.call(vehicle:, attributes:, actor: nil)
      new(vehicle:, attributes:, actor:).call
    end

    def initialize(vehicle:, attributes:, actor:)
      @vehicle = vehicle
      @attributes = attributes.symbolize_keys
      @actor = actor
    end

    def call
      Vehicle.transaction do
        @vehicle.lock! if @vehicle.persisted?
        original_lot_id = @vehicle.lot_id
        destination_id = @attributes[:lot_id].presence&.to_i
        lot_ids = [ original_lot_id, destination_id ].compact.uniq.sort
        lots = Lot.where(id: lot_ids).order(:id).lock.index_by(&:id)
        destination = lots[destination_id] if destination_id

        if destination_id && destination_id != original_lot_id
          occupied = Vehicle.where(lot_id: destination_id).where.not(id: @vehicle.id).count
          raise CapacityExceeded, "#{destination.name} is at capacity" if occupied >= destination.capacity
        end

        @vehicle.assign_attributes(@attributes)
        if @vehicle.save
          if original_lot_id && destination_id && original_lot_id != destination_id
            Move.create!(vehicle: @vehicle, from_lot_id: original_lot_id, to_lot_id: destination_id, moved_by: @actor, reason: "Vehicle record lot assignment", moved_at: Time.current)
          end
          Rails.cache.delete("fleet_metrics:v1")
        end
        @vehicle
      end
    end
  end
end
