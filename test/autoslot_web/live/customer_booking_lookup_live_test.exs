defmodule AutoslotWeb.CustomerBookingLookupLiveTest do
  use AutoslotWeb.ConnCase

  import Phoenix.LiveViewTest
  import Autoslot.ServicesFixtures

  alias Autoslot.Bookings

  defp create_booking(attrs \\ %{}) do
    service =
      service_fixture(%{
        name: "Компьютерная диагностика",
        description: "Проверка электронных систем автомобиля",
        duration_minutes: 30,
        price: 1500
      })

    starts_at = Map.get(attrs, :starts_at, ~N[2026-07-10 10:00:00])
    ends_at = Map.get(attrs, :ends_at, NaiveDateTime.add(starts_at, 30, :minute))

    booking_attrs = %{
      customer_name: Map.get(attrs, :customer_name, "Дмитрий"),
      phone: Map.get(attrs, :phone, "+7 999 123-45-67"),
      vehicle_plate: Map.get(attrs, :vehicle_plate, "А123АА125"),
      starts_at: starts_at,
      ends_at: ends_at,
      status: Map.get(attrs, :status, "pending"),
      service_id: service.id
    }

    {:ok, booking} = Bookings.create_booking(booking_attrs)

    %{booking: booking, service: service}
  end

  test "renders lookup page", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/my-bookings")

    assert html =~ "Мои записи"
    assert html =~ "Поиск по телефону"
  end

  test "finds bookings by phone", %{conn: conn} do
    %{service: service} = create_booking()

    {:ok, live, _html} = live(conn, ~p"/my-bookings")

    html =
      live
      |> form("#booking-lookup-form", lookup: %{phone: "89991234567"})
      |> render_submit()

    assert html =~ "Найденные записи"
    assert html =~ service.name
    assert html =~ "А123АА125"
    assert html =~ "Ожидает"
  end

  test "shows empty state when no bookings found", %{conn: conn} do
    {:ok, live, _html} = live(conn, ~p"/my-bookings")

    html =
      live
      |> form("#booking-lookup-form", lookup: %{phone: "+7 000 000-00-00"})
      |> render_submit()

    assert html =~ "Записи не найдены"
  end

  test "cancels active booking", %{conn: conn} do
    %{booking: booking} = create_booking()

    {:ok, live, _html} = live(conn, ~p"/my-bookings")

    live
    |> form("#booking-lookup-form", lookup: %{phone: "+7 999 123-45-67"})
    |> render_submit()

    assert live |> element("button[phx-value-id='#{booking.id}']", "Отменить") |> render_click()
    assert render(live) =~ "Отменить запись?"

    html =
      live
      |> element("button[phx-value-id='#{booking.id}']", "Да, отменить")
      |> render_click()

    assert html =~ "Запись отменена"
    assert html =~ "Отменена"
  end
end
