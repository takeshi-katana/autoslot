defmodule Autoslot.BookingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Autoslot.Bookings` context.
  """

  @doc """
  Generate a booking.
  """
  def booking_fixture(attrs \\ %{}) do
    {:ok, booking} =
      attrs
      |> Enum.into(%{
        customer_name: "some customer_name",
        ends_at: ~U[2026-07-02 16:29:00Z],
        phone: "some phone",
        starts_at: ~U[2026-07-02 16:29:00Z],
        status: "some status",
        vehicle_plate: "some vehicle_plate"
      })
      |> Autoslot.Bookings.create_booking()

    booking
  end
end
