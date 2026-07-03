defmodule Autoslot.BookingsTest do
  use Autoslot.DataCase

  alias Autoslot.Bookings

  describe "bookings" do
    alias Autoslot.Bookings.Booking

    import Autoslot.BookingsFixtures

    @invalid_attrs %{
      status: nil,
      customer_name: nil,
      phone: nil,
      vehicle_plate: nil,
      starts_at: nil,
      ends_at: nil
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
      valid_attrs = %{
        status: "some status",
        customer_name: "some customer_name",
        phone: "some phone",
        vehicle_plate: "some vehicle_plate",
        starts_at: ~U[2026-07-02 16:29:00Z],
        ends_at: ~U[2026-07-02 16:29:00Z]
      }

      assert {:ok, %Booking{} = booking} = Bookings.create_booking(valid_attrs)
      assert booking.status == "some status"
      assert booking.customer_name == "some customer_name"
      assert booking.phone == "some phone"
      assert booking.vehicle_plate == "some vehicle_plate"
      assert booking.starts_at == ~U[2026-07-02 16:29:00Z]
      assert booking.ends_at == ~U[2026-07-02 16:29:00Z]
    end

    test "create_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_booking(@invalid_attrs)
    end

    test "update_booking/2 with valid data updates the booking" do
      booking = booking_fixture()

      update_attrs = %{
        status: "some updated status",
        customer_name: "some updated customer_name",
        phone: "some updated phone",
        vehicle_plate: "some updated vehicle_plate",
        starts_at: ~U[2026-07-03 16:29:00Z],
        ends_at: ~U[2026-07-03 16:29:00Z]
      }

      assert {:ok, %Booking{} = booking} = Bookings.update_booking(booking, update_attrs)
      assert booking.status == "some updated status"
      assert booking.customer_name == "some updated customer_name"
      assert booking.phone == "some updated phone"
      assert booking.vehicle_plate == "some updated vehicle_plate"
      assert booking.starts_at == ~U[2026-07-03 16:29:00Z]
      assert booking.ends_at == ~U[2026-07-03 16:29:00Z]
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
