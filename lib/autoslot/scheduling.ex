defmodule Autoslot.Scheduling do
  @moduledoc """
  Business logic for calculating available booking time slots.

  The initial MVP uses a simple scheduling model:

  - working hours: 09:00–18:00;
  - slot step: 30 minutes;
  - service duration affects slot length;
  - cancelled bookings do not block time;
  - active overlapping bookings block time slots.
  """

  @workday_start ~T[09:00:00]
  @workday_end ~T[18:00:00]
  @slot_step_minutes 30

  @doc """
  Returns available time slots for a given date, service and existing bookings.

  Each returned slot is a map with `:starts_at` and `:ends_at`.

  ## Example

      iex> service = %Autoslot.Services.Service{duration_minutes: 60}
      iex> Autoslot.Scheduling.available_slots(~D[2026-07-04], service, [])
      [
        %{starts_at: ~U[2026-07-04 09:00:00Z], ends_at: ~U[2026-07-04 10:00:00Z]},
        ...
      ]

  """
  def available_slots(date, service, bookings \\ []) do
    duration_minutes = service.duration_minutes

    date
    |> generate_slots(duration_minutes)
    |> reject_occupied_slots(bookings)
  end

  def slot_options(date, service, bookings \\ []) do
    all_slots = generate_slots(date, service.duration_minutes)
    available_starts = MapSet.new(available_slots(date, service, bookings), & &1.starts_at)

    Enum.map(all_slots, fn slot ->
      Map.put(slot, :available, MapSet.member?(available_starts, slot.starts_at))
    end)
  end

  @doc """
  Checks whether two time intervals overlap.

  Two intervals overlap when the new interval starts before the existing interval ends
  and ends after the existing interval starts.
  """
  def overlaps?(new_start, new_end, existing_start, existing_end) do
    DateTime.compare(new_start, existing_end) == :lt and
      DateTime.compare(new_end, existing_start) == :gt
  end

  defp generate_slots(date, duration_minutes) do
    workday_start = DateTime.new!(date, @workday_start, "Etc/UTC")
    workday_end = DateTime.new!(date, @workday_end, "Etc/UTC")

    latest_start =
      DateTime.add(workday_end, -duration_minutes, :minute)

    do_generate_slots(workday_start, latest_start, duration_minutes, [])
  end

  defp do_generate_slots(current_start, latest_start, duration_minutes, acc) do
    if DateTime.compare(current_start, latest_start) == :gt do
      Enum.reverse(acc)
    else
      current_end = DateTime.add(current_start, duration_minutes, :minute)

      slot = %{
        starts_at: current_start,
        ends_at: current_end
      }

      next_start = DateTime.add(current_start, @slot_step_minutes, :minute)

      do_generate_slots(next_start, latest_start, duration_minutes, [slot | acc])
    end
  end

  defp reject_occupied_slots(slots, bookings) do
    active_bookings =
      Enum.reject(bookings, fn booking ->
        booking.status == "cancelled"
      end)

    Enum.reject(slots, fn slot ->
      Enum.any?(active_bookings, fn booking ->
        overlaps?(
          slot.starts_at,
          slot.ends_at,
          booking.starts_at,
          booking.ends_at
        )
      end)
    end)
  end
end
