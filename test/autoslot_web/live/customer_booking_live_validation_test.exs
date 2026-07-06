defmodule AutoslotWeb.CustomerBookingLiveValidationTest do
  use AutoslotWeb.ConnCase

  import Phoenix.LiveViewTest
  import Autoslot.ServicesFixtures

  alias Autoslot.Scheduling

  test "shows Russian validation messages for required booking fields", %{conn: conn} do
    service =
      service_fixture(%{
        name: "Компьютерная диагностика",
        description: "Проверка электронных систем автомобиля",
        duration_minutes: 30,
        price: 1500
      })

    today = Date.utc_today()
    slot = today |> Scheduling.available_slots(service, []) |> List.first()

    {:ok, booking_live, _html} = live(conn, ~p"/book")

    html =
      render_submit(booking_live, "create_booking", %{
        "service_id" => Integer.to_string(service.id),
        "slot" => DateTime.to_iso8601(slot.starts_at),
        "customer_name" => "",
        "phone" => "",
        "vehicle_plate" => ""
      })

    assert html =~ "Имя клиента: не может быть пустым"
    assert html =~ "Телефон: не может быть пустым"
    assert html =~ "Номер автомобиля: не может быть пустым"
  end
end
