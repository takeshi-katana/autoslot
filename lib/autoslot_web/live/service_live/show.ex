defmodule AutoslotWeb.ServiceLive.Show do
  use AutoslotWeb, :live_view

  alias Autoslot.Services

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Service {@service.id}
        <:subtitle>This is a service record from your database.</:subtitle>

        <:actions>
          <.button navigate={~p"/services"}>
            <.icon name="hero-arrow-left" />
          </.button>

          <.button variant="primary" navigate={~p"/services/#{@service}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit service
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@service.name}</:item>

        <:item title="Description">{@service.description}</:item>

        <:item title="Duration minutes">{@service.duration_minutes}</:item>

        <:item title="Price">{@service.price}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Service")
     |> assign(:service, Services.get_service!(id))}
  end
end
