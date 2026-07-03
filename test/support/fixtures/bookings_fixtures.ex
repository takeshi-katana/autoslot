defmodule Autoslot.BookingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Autoslot.Bookings` context.
  """

  import Autoslot.ServicesFixtures

  def valid_booking_attrs(attrs \\ %{}) do
    service_id =
      Map.get_lazy(attrs, :service_id, fn ->
        service_fixture().id
      end)

    attrs
    |> Enum.into(%{
      customer_name: "Иван Петров",
      phone: "+7 999 123-45-67",
      vehicle_plate: "А123ВС125",
      starts_at: ~U[2026-07-04 09:00:00Z],
      ends_at: ~U[2026-07-04 10:00:00Z],
      status: "pending",
      service_id: service_id
    })
  end

  def booking_fixture(attrs \\ %{}) do
    {:ok, booking} =
      attrs
      |> valid_booking_attrs()
      |> Autoslot.Bookings.create_booking()

    booking
  end
end
