defmodule AutoslotWeb.HealthController do
  use AutoslotWeb, :controller

  def show(conn, _params) do
    send_resp(conn, :ok, "ok")
  end
end
