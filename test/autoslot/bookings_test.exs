defmodule Autoslot.BookingsTest do
  use Autoslot.DataCase

  alias Autoslot.Bookings

  describe "bookings" do
    alias Autoslot.Bookings.Booking

    import Autoslot.BookingsFixtures
    import Autoslot.ServicesFixtures

    @invalid_attrs %{
      customer_name: nil,
      phone: nil,
      vehicle_plate: nil,
      starts_at: nil,
      ends_at: nil,
      status: nil,
      service_id: nil
    }

    test "list_bookings/0 returns all bookings" do
      booking = booking_fixture()
      assert Bookings.list_bookings() == [booking]
    end

    test "get_booking!/1 returns the booking with given id" do
      booking = booking_fixture()
      assert Bookings.get_booking!(booking.id) == booking
    end

    test "create_booking/1 with valid data creates a booking" do
      service = service_fixture()

      valid_attrs = %{
        customer_name: "Иван Петров",
        phone: "+7 999 123-45-67",
        vehicle_plate: "А123ВС125",
        starts_at: ~U[2026-07-04 09:00:00Z],
        ends_at: ~U[2026-07-04 10:00:00Z],
        status: "pending",
        service_id: service.id
      }

      assert {:ok, %Booking{} = booking} = Bookings.create_booking(valid_attrs)
      assert booking.customer_name == "Иван Петров"
      assert booking.phone == "+7 999 123-45-67"
      assert booking.vehicle_plate == "А123ВС125"
      assert booking.starts_at == ~U[2026-07-04 09:00:00Z]
      assert booking.ends_at == ~U[2026-07-04 10:00:00Z]
      assert booking.status == "pending"
      assert booking.service_id == service.id
    end

    test "create_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_booking(@invalid_attrs)
    end

    test "create_booking/1 rejects invalid status" do
      service = service_fixture()

      attrs =
        valid_booking_attrs(%{
          service_id: service.id,
          status: "finished"
        })

      assert {:error, changeset} = Bookings.create_booking(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "create_booking/1 rejects booking when ends_at is before starts_at" do
      service = service_fixture()

      attrs =
        valid_booking_attrs(%{
          service_id: service.id,
          starts_at: ~U[2026-07-04 10:00:00Z],
          ends_at: ~U[2026-07-04 09:00:00Z]
        })

      assert {:error, changeset} = Bookings.create_booking(attrs)
      assert "must be after start time" in errors_on(changeset).ends_at
    end

    test "create_booking/1 rejects booking when ends_at equals starts_at" do
      service = service_fixture()

      attrs =
        valid_booking_attrs(%{
          service_id: service.id,
          starts_at: ~U[2026-07-04 10:00:00Z],
          ends_at: ~U[2026-07-04 10:00:00Z]
        })

      assert {:error, changeset} = Bookings.create_booking(attrs)
      assert "must be after start time" in errors_on(changeset).ends_at
    end

    test "update_booking/2 with valid data updates the booking" do
      booking = booking_fixture()
      new_service = service_fixture(%{name: "Ремонт тормозной системы"})

      update_attrs = %{
        customer_name: "Петр Иванов",
        phone: "+7 999 765-43-21",
        vehicle_plate: "В456СЕ125",
        starts_at: ~U[2026-07-05 11:00:00Z],
        ends_at: ~U[2026-07-05 12:30:00Z],
        status: "confirmed",
        service_id: new_service.id
      }

      assert {:ok, %Booking{} = booking} = Bookings.update_booking(booking, update_attrs)
      assert booking.customer_name == "Петр Иванов"
      assert booking.phone == "+7 999 765-43-21"
      assert booking.vehicle_plate == "В456СЕ125"
      assert booking.starts_at == ~U[2026-07-05 11:00:00Z]
      assert booking.ends_at == ~U[2026-07-05 12:30:00Z]
      assert booking.status == "confirmed"
      assert booking.service_id == new_service.id
    end

    test "update_booking/2 with invalid data returns error changeset" do
      booking = booking_fixture()
      assert {:error, %Ecto.Changeset{}} = Bookings.update_booking(booking, @invalid_attrs)
      assert booking == Bookings.get_booking!(booking.id)
    end

    test "delete_booking/1 deletes the booking" do
      booking = booking_fixture()
      assert {:ok, %Booking{}} = Bookings.delete_booking(booking)
      assert_raise Ecto.NoResultsError, fn -> Bookings.get_booking!(booking.id) end
    end

    test "change_booking/1 returns a booking changeset" do
      booking = booking_fixture()
      assert %Ecto.Changeset{} = Bookings.change_booking(booking)
    end
  end
end
