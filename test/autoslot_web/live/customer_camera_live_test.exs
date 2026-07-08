defmodule AutoslotWeb.CustomerCameraLiveTest do
  use AutoslotWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders customer camera page", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/cameras")

    assert html =~ "Онлайн-камеры ремонтных боксов"
    assert html =~ "Бокс 1"
    assert html =~ "Бокс 2"
    assert html =~ "Бокс 3"
    assert html =~ "Бокс 4"
    assert html =~ "Открыть демо-камеры"
  end
end
