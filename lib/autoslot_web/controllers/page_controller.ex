defmodule AutoslotWeb.PageController do
  use AutoslotWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
