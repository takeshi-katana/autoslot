defmodule AutoslotWeb.Router do
  use AutoslotWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AutoslotWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AutoslotWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/book", CustomerBookingLive
    live "/admin/bookings", AdminBookingLive

    live "/services", ServiceLive.Index, :index
    live "/services/new", ServiceLive.Form, :new
    live "/services/:id/edit", ServiceLive.Form, :edit
    live "/services/:id", ServiceLive.Show, :show
  end

  if Application.compile_env(:autoslot, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AutoslotWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
