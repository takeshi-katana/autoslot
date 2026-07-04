defmodule AutoslotWeb.ServiceLive.Index do
  use AutoslotWeb, :live_view

  alias Autoslot.Services

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-6 py-10">
      <div class="mx-auto max-w-7xl">
        <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <a href="/" class="text-sm text-primary hover:underline">← На главную</a>

            <h1 class="mt-4 text-4xl font-bold text-base-content">
              Каталог услуг
            </h1>

            <p class="mt-3 max-w-3xl text-base-content/70">
              Управление услугами автосервиса: название, описание, длительность и ориентировочная цена.
              Эти услуги отображаются клиенту на странице онлайн-записи.
            </p>
          </div>

          <div class="flex gap-3">
            <a href="/book" class="btn btn-outline">Страница клиента</a>

            <.button variant="primary" navigate={~p"/services/new"}>
              <.icon name="hero-plus" /> Добавить услугу
            </.button>
          </div>
        </div>

        <%= if @service_count == 0 do %>
          <section class="rounded-xl bg-base-100 p-10 text-center shadow">
            <h2 class="text-2xl font-semibold">Услуги пока не добавлены</h2>

            <p class="mt-3 text-base-content/60">
              Создайте первую услугу вручную или запустите seed-данные.
            </p>

            <.button variant="primary" navigate={~p"/services/new"} class="mt-6">
              <.icon name="hero-plus" /> Добавить услугу
            </.button>
          </section>
        <% else %>
          <section class="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
            <%= for {id, service} <- @streams.services do %>
              <article
                id={id}
                class="flex min-h-72 flex-col rounded-2xl bg-base-100 p-6 shadow transition hover:-translate-y-1 hover:shadow-xl"
              >
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <h2 class="text-2xl font-bold text-base-content">
                      {service.name}
                    </h2>

                    <div class="mt-3 flex flex-wrap gap-2">
                      <span class="badge badge-primary">
                        {service.duration_minutes} мин.
                      </span>

                      <span class="badge badge-outline">
                        {service.price} ₽
                      </span>
                    </div>
                  </div>
                </div>

                <p class="mt-5 flex-1 text-base leading-7 text-base-content/70">
                  {service.description}
                </p>

                <div class="mt-6 flex flex-wrap gap-2 border-t border-base-300 pt-5">
                  <.link navigate={~p"/services/#{service}"} class="btn btn-outline btn-sm">
                    Открыть
                  </.link>

                  <.link navigate={~p"/services/#{service}/edit"} class="btn btn-primary btn-sm">
                    Редактировать
                  </.link>

                  <button
                    type="button"
                    phx-click={JS.push("delete", value: %{id: service.id})}
                    data-confirm="Удалить услугу?"
                    class="btn btn-error btn-sm"
                  >
                    Удалить
                  </button>
                </div>
              </article>
            <% end %>
          </section>
        <% end %>
      </div>
    </main>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    services = list_services()

    {:ok,
     socket
     |> assign(:page_title, "Каталог услуг")
     |> assign(:service_count, length(services))
     |> stream(:services, services)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    service = Services.get_service!(id)
    {:ok, _} = Services.delete_service(service)

    socket =
      socket
      |> assign(:service_count, max(socket.assigns.service_count - 1, 0))
      |> stream_delete(:services, service)

    {:noreply, socket}
  end

  defp list_services do
    Services.list_services()
  end
end
