defmodule Autoslot.SchedulingTest do
  use ExUnit.Case, async: true

  alias Autoslot.Scheduling
  alias Autoslot.Services.Service

  test "generates slots inside the workday and marks overlaps unavailable" do
    service = %Service{duration_minutes: 60}

    booking = %{
      starts_at: ~U[2026-07-04 10:00:00Z],
      ends_at: ~U[2026-07-04 11:00:00Z],
      status: "confirmed"
    }

    slots = Scheduling.slot_options(~D[2026-07-04], service, [booking])

    assert hd(slots).starts_at == ~U[2026-07-04 09:00:00Z]
    assert List.last(slots).ends_at == ~U[2026-07-04 18:00:00Z]
    refute Enum.find(slots, &(&1.starts_at == ~U[2026-07-04 10:00:00Z])).available

    assert Scheduling.overlaps?(
             ~U[2026-07-04 09:30:00Z],
             ~U[2026-07-04 10:30:00Z],
             booking.starts_at,
             booking.ends_at
           )

    refute Scheduling.overlaps?(
             ~U[2026-07-04 09:00:00Z],
             ~U[2026-07-04 10:00:00Z],
             booking.starts_at,
             booking.ends_at
           )
  end
end
