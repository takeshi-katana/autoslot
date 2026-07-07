defmodule AutoslotWeb.AdminSessionController do
  use AutoslotWeb, :controller

  alias AutoslotWeb.AdminAuth

  plug AutoslotWeb.AdminAuth, :redirect_if_admin_authenticated when action in [:new]

  def new(conn, _params) do
    render_login(conn)
  end

  def create(conn, %{"admin" => %{"username" => username, "password" => password}}) do
    if valid_admin_credentials?(username, password) do
      conn
      |> AdminAuth.log_in_admin()
      |> put_flash(:info, "Вы вошли в административную панель.")
      |> redirect(to: ~p"/admin/bookings")
    else
      conn
      |> put_status(:unauthorized)
      |> put_flash(:error, "Неверный логин или пароль администратора.")
      |> render_login(username)
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> put_flash(:error, "Введите логин и пароль администратора.")
    |> render_login()
  end

  def delete(conn, _params) do
    conn
    |> AdminAuth.log_out_admin()
    |> put_flash(:info, "Вы вышли из административной панели.")
    |> redirect(to: ~p"/admin/login")
  end

  defp render_login(conn, username \\ "") do
    render(conn, :new,
      page_title: "Вход администратора",
      form: Phoenix.Component.to_form(%{"username" => username}, as: :admin)
    )
  end

  defp valid_admin_credentials?(username, password) do
    secure_equals?(username, admin_username()) and secure_equals?(password, admin_password())
  end

  defp admin_username do
    Application.get_env(:autoslot, :admin_username) ||
      System.get_env("AUTOSLOT_ADMIN_USERNAME") ||
      "admin"
  end

  defp admin_password do
    Application.get_env(:autoslot, :admin_password) ||
      System.get_env("AUTOSLOT_ADMIN_PASSWORD") ||
      "autoslot"
  end

  defp secure_equals?(left, right) when is_binary(left) and is_binary(right) do
    byte_size(left) == byte_size(right) and Plug.Crypto.secure_compare(left, right)
  end

  defp secure_equals?(_left, _right), do: false
end
