defmodule AutoslotWeb.ServiceLive.Form do
  use AutoslotWeb, :live_view

  alias Autoslot.Services
  alias Autoslot.Services.Service

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-6 py-10">
      <div class="mx-auto max-w-5xl">
        <div class="mb-8">
          <a href={return_path(@return_to, @service)} class="text-sm text-primary hover:underline">
            ← Назад
          </a>

          <h1 class="mt-4 text-4xl font-bold text-base-content">
            {@page_title}
          </h1>

          <p class="mt-3 max-w-2xl text-base-content/70">
            Заполните данные услуги, которую клиент сможет выбрать на странице онлайн-записи.
            Длительность используется при расчете свободных временных слотов.
          </p>
        </div>

        <section class="grid gap-6 lg:grid-cols-[1fr_320px]">
          <div class="rounded-2xl bg-base-100 p-6 shadow">
            <.form
              for={@form}
              id="service-form"
              phx-change="validate"
              phx-submit="save"
              class="grid gap-5"
            >
              <.input field={@form[:name]} type="text" label="Название" />
              <.input field={@form[:description]} type="textarea" label="Описание" />
              <.input
                field={@form[:duration_minutes]}
                type="number"
                label="Длительность, минут"
              />
              <.input field={@form[:price]} type="number" label="Цена, ₽" />

              <div class="mt-2 flex flex-wrap gap-3 border-t border-base-300 pt-5">
                <button
                  type="submit"
                  class="btn btn-primary"
                  phx-disable-with="Сохранение..."
                >
                  Сохранить услугу
                </button>

                <a href={return_path(@return_to, @service)} class="btn btn-outline">
                  Отмена
                </a>
              </div>
            </.form>
          </div>

          <aside class="rounded-2xl bg-base-100 p-6 shadow">
            <h2 class="text-xl font-semibold">Как это используется</h2>

            <div class="mt-5 grid gap-4 text-sm text-base-content/70">
              <div class="rounded-xl border border-base-300 p-4">
                <div class="font-semibold text-base-content">Название</div>
                <p class="mt-1">Показывается клиенту в списке доступных услуг.</p>
              </div>

              <div class="rounded-xl border border-base-300 p-4">
                <div class="font-semibold text-base-content">Длительность</div>
                <p class="mt-1">Влияет на расчет свободных слотов для записи.</p>
              </div>

              <div class="rounded-xl border border-base-300 p-4">
                <div class="font-semibold text-base-content">Цена</div>
                <p class="mt-1">Используется как ориентир для клиента до визита в сервис.</p>
              </div>
            </div>
          </aside>
        </section>
      </div>
    </main>
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
    |> assign(:page_title, "Редактирование услуги")
    |> assign(:service, service)
    |> assign(:form, to_form(Services.change_service(service)))
  end

  defp apply_action(socket, :new, _params) do
    service = %Service{}

    socket
    |> assign(:page_title, "Новая услуга")
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
         |> put_flash(:info, "Услуга обновлена")
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
         |> put_flash(:info, "Услуга создана")
         |> push_navigate(to: return_path(socket.assigns.return_to, service))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _service), do: ~p"/services"
  defp return_path("show", service), do: ~p"/services/#{service}"
end
