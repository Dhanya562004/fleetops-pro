require "test_helper"

# Concurrency test for Lots::MoveVehicle
#
# Why self.use_transactional_tests = false is needed:
# Rails defaults to wrapping every test method in an outer database transaction that rolls
# back when the test finishes. In PostgreSQL, uncommitted rows from one transaction are
# completely isolated and invisible to other database connections.
# When multi-threaded code runs, each thread acquires its own connection from the ActiveRecord
# connection pool. Under transactional tests, secondary threads cannot access the uncommitted
# test records created by the test runner thread, and row-level locks (e.g., SELECT ... FOR UPDATE)
# cannot be evaluated across separate transaction boundaries.
#
# Disabling transactional tests allows each thread to open its own true database transaction,
# compete for real PostgreSQL row-level locks, and verify that pessimistic locking correctly
# serializes concurrent moves without overfilling the destination lot. Because changes are
# committed to the database, manual cleanup in teardown is mandatory.
class Lots::MoveVehicleConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @vehicles = []
    @destination = create_lot(name: "Target Lot", capacity: 3)
    @source = create_lot(name: "Source Lot", capacity: 10)

    # Fill destination lot with 2 vehicles so only ONE free space remains
    2.times do
      vehicle = create_vehicle(lot: @destination)
      @vehicles << vehicle
    end
  end

  teardown do
    # Clean up non-transactional committed records
    if @vehicles.present?
      vehicle_ids = @vehicles.map(&:id)
      Move.where(vehicle_id: vehicle_ids).delete_all
      Vehicle.where(id: vehicle_ids).delete_all
    end
    @destination&.destroy
    @source&.destroy
  end

  test "N threads race to move vehicles into a lot with only one free space" do
    thread_count = 5
    racer_vehicles = thread_count.times.map do
      vehicle = create_vehicle(lot: @source)
      @vehicles << vehicle
      vehicle
    end

    # Barrier synchronization to ensure all threads race at the exact same moment
    mutex = Mutex.new
    cv = ConditionVariable.new
    ready_count = 0
    start_signal = false

    threads = racer_vehicles.map do |vehicle|
      Thread.new do
        mutex.synchronize do
          ready_count += 1
          cv.signal if ready_count == thread_count
          cv.wait(mutex) until start_signal
        end

        Lots::MoveVehicle.call(
          vehicle:,
          to_lot: @destination,
          reason: "Concurrent race slot test"
        )
        :success
      rescue Lots::MoveVehicle::CapacityExceeded
        :capacity_exceeded
      ensure
        ActiveRecord::Base.connection_handler.clear_active_connections!
      end
    end

    # Release all threads simultaneously once all are waiting
    mutex.synchronize do
      cv.wait(mutex) until ready_count == thread_count
      start_signal = true
      cv.broadcast
    end

    results = threads.map(&:value)

    successes = results.count(:success)
    rejections = results.count(:capacity_exceeded)

    assert_equal 1, successes, "Exactly one thread should claim the single free space"
    assert_equal(thread_count - 1, rejections, "All other racing threads should receive CapacityExceeded")

    # Invariant: lot capacity must never be exceeded
    final_count = @destination.reload.vehicles.count
    assert_equal @destination.capacity, final_count
    assert_operator final_count, :<=, @destination.capacity, "Lot count must never exceed capacity"
  end
end
