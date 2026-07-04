defmodule AutoslotWeb.ServiceLive.Index do
  use AutoslotWeb, :live_view

  alias Autoslot.Services

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Services
        <:actions>
          <.button variant="primary" navigate={~p"/services/new"}>
            <.icon name="hero-plus" /> New Service
          </.button>
        </:actions>
      </.header>

      <.table
        id="services"
        rows={@streams.services}
        row_click={fn {_id, service} -> JS.navigate(~p"/services/#{service}") end}
      >
        <:col :let={{_id, service}} label="Name">{service.name}</:col>

        <:col :let={{_id, service}} label="Description">{service.description}</:col>

        <:col :let={{_id, service}} label="Duration minutes">{service.duration_minutes}</:col>

        <:col :let={{_id, service}} label="Price">{service.price}</:col>

        <:action :let={{_id, service}}>
          <div class="sr-only">
            <.link navigate={~p"/services/#{service}"}>Show</.link>
          </div>
          <.link navigate={~p"/services/#{service}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, service}}>
          <.link
            phx-click={JS.push("delete", value: %{id: service.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Services")
     |> stream(:services, list_services())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    service = Services.get_service!(id)
    {:ok, _} = Services.delete_service(service)

    {:noreply, stream_delete(socket, :services, service)}
  end

  defp list_services() do
    Services.list_services()
  end
end
