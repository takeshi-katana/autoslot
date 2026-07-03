defmodule AutoslotWeb.ServiceLive.Form do
  use AutoslotWeb, :live_view

  alias Autoslot.Services
  alias Autoslot.Services.Service

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage service records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="service-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:duration_minutes]} type="number" label="Duration minutes" />
        <.input field={@form[:price]} type="number" label="Price" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Service</.button>
          <.button navigate={return_path(@return_to, @service)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    service = Services.get_service!(id)

    socket
    |> assign(:page_title, "Edit Service")
    |> assign(:service, service)
    |> assign(:form, to_form(Services.change_service(service)))
  end

  defp apply_action(socket, :new, _params) do
    service = %Service{}

    socket
    |> assign(:page_title, "New Service")
    |> assign(:service, service)
    |> assign(:form, to_form(Services.change_service(service)))
  end

  @impl true
  def handle_event("validate", %{"service" => service_params}, socket) do
    changeset = Services.change_service(socket.assigns.service, service_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"service" => service_params}, socket) do
    save_service(socket, socket.assigns.live_action, service_params)
  end

  defp save_service(socket, :edit, service_params) do
    case Services.update_service(socket.assigns.service, service_params) do
      {:ok, service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Service updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, service))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_service(socket, :new, service_params) do
    case Services.create_service(service_params) do
      {:ok, service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Service created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, service))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _service), do: ~p"/services"
  defp return_path("show", service), do: ~p"/services/#{service}"
end
