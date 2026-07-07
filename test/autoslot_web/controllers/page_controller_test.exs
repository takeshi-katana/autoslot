defmodule AutoslotWeb.PageControllerTest do
  use AutoslotWeb.ConnCase

  test "GET / renders KagamiAuto homepage", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "KagamiAuto"
    assert response =~ "Онлайн-запись для автосервиса"
    assert response =~ "Создать запись"
    assert response =~ "Смотреть услуги"
  end
end
