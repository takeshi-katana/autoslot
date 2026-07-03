defmodule Autoslot.SchedulingTest do
  use Autoslot.DataCase

  alias Autoslot.Bookings.Booking
  alias Autoslot.Scheduling
  alias Autoslot.Services.Service

  describe "available_slots/3" do
    test "returns all slots for empty day" do
      service = %Service{duration_minutes: 60}

      slots = Scheduling.available_slots(~D[2026-07-04], service, [])

      assert length(slots) == 17

      assert hd(slots) == %{
               starts_at: ~U[2026-07-04 09:00:00Z],
               ends_at: ~U[2026-07-04 10:00:00Z]
             }

      assert List.last(slots) == %{
               starts_at: ~U[2026-07-04 17:00:00Z],
               ends_at: ~U[2026-07-04 18:00:00Z]
             }
    end

    test "uses service duration to calculate slot end time" do
      service = %Service{duration_minutes: 90}

      [first_slot | _rest] = Scheduling.available_slots(~D[2026-07-04], service, [])

      assert first_slot.starts_at == ~U[2026-07-04 09:00:00Z]
      assert first_slot.ends_at == ~U[2026-07-04 10:30:00Z]
    end

    test "does not create slots outside working hours" do
      service = %Service{duration_minutes: 90}

      slots = Scheduling.available_slots(~D[2026-07-04], service, [])

      assert List.last(slots) == %{
               starts_at: ~U[2026-07-04 16:30:00Z],
               ends_at: ~U[2026-07-04 18:00:00Z]
             }
    end

    test "removes slots that overlap with existing pending booking" do
      service = %Service{duration_minutes: 60}

      existing_booking = %Booking{
        starts_at: ~U[2026-07-04 10:00:00Z],
        ends_at: ~U[2026-07-04 11:00:00Z],
        status: "pending"
      }

      slots = Scheduling.available_slots(~D[2026-07-04], service, [existing_booking])

      refute %{starts_at: ~U[2026-07-04 09:30:00Z], ends_at: ~U[2026-07-04 10:30:00Z]} in slots
      refute %{starts_at: ~U[2026-07-04 10:00:00Z], ends_at: ~U[2026-07-04 11:00:00Z]} in slots
      refute %{starts_at: ~U[2026-07-04 10:30:00Z], ends_at: ~U[2026-07-04 11:30:00Z]} in slots

      assert %{starts_at: ~U[2026-07-04 09:00:00Z], ends_at: ~U[2026-07-04 10:00:00Z]} in slots
      assert %{starts_at: ~U[2026-07-04 11:00:00Z], ends_at: ~U[2026-07-04 12:00:00Z]} in slots
    end

    test "removes slots that overlap with existing confirmed booking" do
      service = %Service{duration_minutes: 60}

      existing_booking = %Booking{
        starts_at: ~U[2026-07-04 13:00:00Z],
        ends_at: ~U[2026-07-04 14:00:00Z],
        status: "confirmed"
      }

      slots = Scheduling.available_slots(~D[2026-07-04], service, [existing_booking])

      refute %{starts_at: ~U[2026-07-04 12:30:00Z], ends_at: ~U[2026-07-04 13:30:00Z]} in slots
      refute %{starts_at: ~U[2026-07-04 13:00:00Z], ends_at: ~U[2026-07-04 14:00:00Z]} in slots
      refute %{starts_at: ~U[2026-07-04 13:30:00Z], ends_at: ~U[2026-07-04 14:30:00Z]} in slots
    end

    test "cancelled booking does not block slots" do
      service = %Service{duration_minutes: 60}

      cancelled_booking = %Booking{
        starts_at: ~U[2026-07-04 10:00:00Z],
        ends_at: ~U[2026-07-04 11:00:00Z],
        status: "cancelled"
      }

      slots = Scheduling.available_slots(~D[2026-07-04], service, [cancelled_booking])

      assert %{starts_at: ~U[2026-07-04 09:30:00Z], ends_at: ~U[2026-07-04 10:30:00Z]} in slots
      assert %{starts_at: ~U[2026-07-04 10:00:00Z], ends_at: ~U[2026-07-04 11:00:00Z]} in slots
      assert %{starts_at: ~U[2026-07-04 10:30:00Z], ends_at: ~U[2026-07-04 11:30:00Z]} in slots
    end
  end

  describe "overlaps?/4" do
    test "returns true when intervals overlap" do
      assert Scheduling.overlaps?(
               ~U[2026-07-04 10:30:00Z],
               ~U[2026-07-04 11:30:00Z],
               ~U[2026-07-04 10:00:00Z],
               ~U[2026-07-04 11:00:00Z]
             )
    end

    test "returns false when intervals touch but do not overlap" do
      refute Scheduling.overlaps?(
               ~U[2026-07-04 11:00:00Z],
               ~U[2026-07-04 12:00:00Z],
               ~U[2026-07-04 10:00:00Z],
               ~U[2026-07-04 11:00:00Z]
             )
    end
  end
end
