defmodule AutoslotWeb.AdminAuth do
  import Phoenix.Controller
  import Phoenix.LiveView, only: []
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, :require_admin), do: require_admin(conn)
  def call(conn, :redirect_if_admin_authenticated), do: redirect_if_admin_authenticated(conn)

  def require_admin(conn) do
    if admin_logged_in?(conn) do
      conn
    else
      conn
      |> put_flash(:error, "Войдите как администратор, чтобы открыть панель управления.")
      |> redirect(to: "/admin/login")
      |> halt()
    end
  end

  def redirect_if_admin_authenticated(conn) do
    if admin_logged_in?(conn) do
      conn
      |> redirect(to: "/admin/bookings")
      |> halt()
    else
      conn
    end
  end

  def admin_logged_in?(conn) do
    get_session(conn, :admin_authenticated) == true
  end

  def log_in_admin(conn) do
    conn
    |> configure_session(renew: true)
    |> put_session(:admin_authenticated, true)
  end

  def log_out_admin(conn) do
    conn
    |> configure_session(renew: true)
    |> delete_session(:admin_authenticated)
  end

  def on_mount(:require_admin, _params, session, socket) do
    if session["admin_authenticated"] == true do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/admin/login")}
    end
  end
end
