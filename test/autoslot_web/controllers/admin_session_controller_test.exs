defmodule AutoslotWeb.AdminSessionControllerTest do
  use AutoslotWeb.ConnCase

  test "GET /admin/bookings redirects guest to admin login", %{conn: conn} do
    conn = get(conn, ~p"/admin/bookings")

    assert redirected_to(conn) == ~p"/admin/login"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Войдите как администратор"
  end

  test "GET /admin/login renders login page", %{conn: conn} do
    conn = get(conn, ~p"/admin/login")
    response = html_response(conn, 200)

    assert response =~ "Вход администратора"
    assert response =~ "Демо-доступ"
  end

  test "POST /admin/login rejects invalid credentials", %{conn: conn} do
    conn =
      post(conn, ~p"/admin/login", %{
        "admin" => %{"username" => "wrong", "password" => "wrong"}
      })

    response = html_response(conn, 401)

    assert response =~ "Неверный логин или пароль администратора"
  end

  test "POST /admin/login signs admin in and allows access to admin bookings", %{conn: conn} do
    conn =
      post(conn, ~p"/admin/login", %{
        "admin" => %{"username" => "admin", "password" => "autoslot"}
      })

    assert redirected_to(conn) == ~p"/admin/bookings"
    assert get_session(conn, :admin_authenticated) == true

    conn =
      conn
      |> recycle()
      |> get(~p"/admin/bookings")

    assert html_response(conn, 200)
  end

  test "GET /admin/logout signs admin out", %{conn: conn} do
    conn =
      post(conn, ~p"/admin/login", %{
        "admin" => %{"username" => "admin", "password" => "autoslot"}
      })

    assert get_session(conn, :admin_authenticated) == true

    conn =
      conn
      |> recycle()
      |> get(~p"/admin/logout")

    assert redirected_to(conn) == ~p"/admin/login"
    refute get_session(conn, :admin_authenticated)
  end
end
