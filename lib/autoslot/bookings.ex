defmodule Autoslot.Bookings do
  @moduledoc """
  The Bookings context.

  This context contains business logic for customer bookings.

  Main responsibilities:

  - listing bookings;
  - creating bookings;
  - updating bookings;
  - deleting bookings;
  - preventing active booking time overlaps.
  """

  import Ecto.Query, warn: false

  alias Autoslot.Bookings.Booking
  alias Autoslot.Repo

  @doc """
  Returns the list of bookings.
  """
  def list_bookings do
    Repo.all(Booking)
  end

  @doc """
  Returns bookings for a specific date.

  The date is interpreted as a UTC calendar day.
  """
  def list_bookings_for_date(%Date{} = date) do
    {day_start, next_day_start} = date_range(date)

    Booking
    |> where([booking], booking.starts_at >= ^day_start)
    |> where([booking], booking.starts_at < ^next_day_start)
    |> order_by([booking], asc: booking.starts_at)
    |> Repo.all()
  end

  @doc """
  Returns bookings for a specific date with preloaded services.

  This function is intended for admin-facing screens where service names
  should be displayed together with booking data.
  """
  def list_bookings_with_services_for_date(%Date{} = date) do
    date
    |> list_bookings_for_date()
    |> Repo.preload(:service)
  end

  @doc """
  Returns active bookings for a specific date.

  Cancelled bookings are excluded because they should not block time slots.
  """
  def list_active_bookings_for_date(%Date{} = date) do
    {day_start, next_day_start} = date_range(date)

    Booking
    |> where([booking], booking.starts_at >= ^day_start)
    |> where([booking], booking.starts_at < ^next_day_start)
    |> where([booking], booking.status != "cancelled")
    |> order_by([booking], asc: booking.starts_at)
    |> Repo.all()
  end

  @doc """
  Gets a single booking.

  Raises `Ecto.NoResultsError` if the Booking does not exist.
  """
  def get_booking!(id), do: Repo.get!(Booking, id)

  @doc """
  Creates a booking.

  Active bookings are not allowed to overlap in time.
  """
  def create_booking(attrs \\ %{}) do
    %Booking{}
    |> Booking.changeset(attrs)
    |> validate_no_time_overlap()
    |> Repo.insert()
  end

  @doc """
  Updates a booking.

  Active bookings are not allowed to overlap in time.
  When updating an existing booking, the booking itself is excluded from the overlap check.
  """
  def update_booking(%Booking{} = booking, attrs) do
    booking
    |> Booking.changeset(attrs)
    |> validate_no_time_overlap(booking.id)
    |> Repo.update()
  end

  @doc """
  Deletes a booking.
  """
  def delete_booking(%Booking{} = booking) do
    Repo.delete(booking)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking booking changes.
  """
  def change_booking(%Booking{} = booking, attrs \\ %{}) do
    Booking.changeset(booking, attrs)
  end

  defp validate_no_time_overlap(changeset, ignored_booking_id \\ nil) do
    if changeset.valid? do
      starts_at = Ecto.Changeset.get_field(changeset, :starts_at)
      ends_at = Ecto.Changeset.get_field(changeset, :ends_at)
      status = Ecto.Changeset.get_field(changeset, :status)

      if status == "cancelled" do
        changeset
      else
        maybe_add_overlap_error(changeset, starts_at, ends_at, ignored_booking_id)
      end
    else
      changeset
    end
  end

  defp maybe_add_overlap_error(changeset, starts_at, ends_at, ignored_booking_id) do
    if overlapping_booking_exists?(starts_at, ends_at, ignored_booking_id) do
      Ecto.Changeset.add_error(
        changeset,
        :starts_at,
        "overlaps with existing active booking"
      )
    else
      changeset
    end
  end

  defp overlapping_booking_exists?(starts_at, ends_at, ignored_booking_id) do
    Booking
    |> where([booking], booking.status != "cancelled")
    |> where([booking], booking.starts_at < ^ends_at)
    |> where([booking], booking.ends_at > ^starts_at)
    |> maybe_ignore_booking(ignored_booking_id)
    |> Repo.exists?()
  end

  defp maybe_ignore_booking(query, nil), do: query

  defp maybe_ignore_booking(query, ignored_booking_id) do
    where(query, [booking], booking.id != ^ignored_booking_id)
  end

  defp date_range(%Date{} = date) do
    day_start = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    next_day_start = DateTime.add(day_start, 1, :day)

    {day_start, next_day_start}
  end
end
