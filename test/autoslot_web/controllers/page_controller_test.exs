defmodule AutoslotWeb.PageControllerTest do
  use AutoslotWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "AutoSlot"
    assert response =~ "онлайн-запись"
  end
end
