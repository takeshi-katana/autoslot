defmodule AutoslotWeb.CustomerBookingLivePastDateTest do
  use AutoslotWeb.ConnCase

  import Phoenix.LiveViewTest
  import Autoslot.ServicesFixtures

  test "normalizes a past booking date back to today", %{conn: conn} do
    service =
      service_fixture(%{
        name: "Компьютерная диагностика",
        description: "Проверка электронных систем автомобиля",
        duration_minutes: 30,
        price: 1500
      })

    today = Date.utc_today()
    past_date = Date.add(today, -1)

    {:ok, booking_live, _html} = live(conn, ~p"/book")

    html =
      render_change(booking_live, "change_selection", %{
        "service_id" => Integer.to_string(service.id),
        "date" => Date.to_iso8601(past_date)
      })

    assert html =~ "value=\"#{Date.to_iso8601(today)}\""
    refute html =~ "value=\"#{Date.to_iso8601(past_date)}\""
    assert html =~ "Запись доступна с сегодняшней даты."
  end
end
