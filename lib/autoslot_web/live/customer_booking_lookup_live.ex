defmodule AutoslotWeb.CustomerBookingLookupLive do
  use AutoslotWeb, :live_view

  alias Autoslot.Bookings.CustomerLookup

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Мои записи")
     |> assign(:form, to_form(%{"phone" => ""}, as: :lookup))
     |> assign(:phone, "")
     |> assign(:bookings, [])
     |> assign(:searched?, false)
     |> assign(:booking_to_cancel, nil)
     |> assign(:notice, nil)
     |> assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-transparent px-6 py-10">
      <div class="mx-auto max-w-6xl">
        <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <a href="/" class="text-sm text-primary hover:underline">← На главную</a>
            <h1 class="mt-4 text-4xl font-semibold text-base-content">
              Мои записи
            </h1>
            
            <p class="mt-3 max-w-3xl text-base-content/70">
              Введите номер телефона, который был указан при записи. Система покажет найденные
              заявки, их статус и позволит отменить активную запись без звонка администратору.
            </p>
          </div>
          
          <a href="/book" class="btn btn-primary">
            Создать новую запись
          </a>
        </div>
        
        <section class="grid gap-6 lg:grid-cols-[360px_1fr]">
          <aside class="rounded-3xl border border-white/10 bg-base-100/80 p-6 shadow-2xl backdrop-blur-xl">
            <h2 class="text-xl font-semibold">Поиск по телефону</h2>
            
            <.form for={@form} id="booking-lookup-form" phx-submit="search" class="mt-5 grid gap-4">
              <.input
                field={@form[:phone]}
                type="text"
                label="Телефон"
                placeholder="+7 999 123-45-67"
              />
              <button type="submit" class="btn btn-primary">
                Найти записи
              </button>
            </.form>
            
            <div class="mt-6 rounded-2xl border border-white/10 bg-base-200/70 p-4 text-sm text-base-content/70">
              <div class="font-semibold text-base-content">Пример</div>
              
              <p class="mt-1">
                Можно вводить телефон с пробелами, скобками и дефисами. Для поиска используются
                цифры номера.
              </p>
            </div>
          </aside>
          
          <section class="rounded-3xl border border-white/10 bg-base-100/80 p-6 shadow-2xl backdrop-blur-xl">
            <%= if @notice do %>
              <div class="alert alert-success mb-5">
                {@notice}
              </div>
            <% end %>
            
            <%= if @error do %>
              <div class="alert alert-error mb-5">
                {@error}
              </div>
            <% end %>
            
            <%= cond do %>
              <% not @searched? -> %>
                <div class="flex min-h-72 items-center justify-center rounded-2xl border border-dashed border-white/20 bg-base-200/40 p-8 text-center">
                  <div>
                    <h2 class="text-2xl font-semibold">Введите телефон</h2>
                    
                    <p class="mt-3 max-w-xl text-base-content/60">
                      Здесь появятся записи клиента: услуга, дата, время, статус и действие
                      для отмены.
                    </p>
                  </div>
                </div>
              <% Enum.empty?(@bookings) -> %>
                <div class="flex min-h-72 items-center justify-center rounded-2xl border border-dashed border-white/20 bg-base-200/40 p-8 text-center">
                  <div>
                    <h2 class="text-2xl font-semibold">Записи не найдены</h2>
                    
                    <p class="mt-3 max-w-xl text-base-content/60">
                      Проверьте номер телефона или создайте новую запись на услугу.
                    </p>
                    
                    <a href="/book" class="btn btn-primary mt-6">
                      Создать запись
                    </a>
                  </div>
                </div>
              <% true -> %>
                <div class="mb-5 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <h2 class="text-2xl font-semibold">Найденные записи</h2>
                    
                    <p class="mt-1 text-sm text-base-content/60">
                      Телефон: {@phone}
                    </p>
                  </div>
                  
                  <div class="badge badge-outline badge-lg">
                    {length(@bookings)} шт.
                  </div>
                </div>
                
                <div class="grid gap-4">
                  <%= for booking <- @bookings do %>
                    <article class="rounded-2xl border border-white/10 bg-base-200/50 p-5">
                      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                        <div>
                          <div class="flex flex-wrap items-center gap-2">
                            <h3 class="text-xl font-semibold">
                              {service_name(booking)}
                            </h3>
                            
                            <span class={status_class(booking.status)}>
                              {status_label(booking.status)}
                            </span>
                          </div>
                          
                          <div class="mt-3 grid gap-2 text-sm text-base-content/70 sm:grid-cols-2">
                            <div>
                              <span class="font-semibold text-base-content">Дата и время:</span> {format_datetime(
                                booking.starts_at
                              )}
                            </div>
                            
                            <div>
                              <span class="font-semibold text-base-content">Автомобиль:</span> {booking.vehicle_plate}
                            </div>
                            
                            <div>
                              <span class="font-semibold text-base-content">Клиент:</span> {booking.customer_name}
                            </div>
                            
                            <div>
                              <span class="font-semibold text-base-content">Телефон:</span> {booking.phone}
                            </div>
                          </div>
                        </div>
                        
                        <%= if CustomerLookup.active?(booking) do %>
                          <button
                            type="button"
                            class="btn btn-error btn-sm"
                            phx-click="request_cancel"
                            phx-value-id={booking.id}
                          >
                            Отменить
                          </button>
                        <% else %>
                          <button type="button" class="btn btn-disabled btn-sm">
                            Отмена недоступна
                          </button>
                        <% end %>
                      </div>
                    </article>
                  <% end %>
                </div>
            <% end %>
          </section>
        </section>
        
        <%= if @booking_to_cancel do %>
          <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-6">
            <div class="w-full max-w-lg rounded-3xl border border-white/10 bg-base-100 p-6 shadow-2xl">
              <h2 class="text-2xl font-semibold">Отменить запись?</h2>
              
              <p class="mt-3 text-base-content/70">
                Запись на услугу "{service_name(@booking_to_cancel)}" будет переведена в статус
                "Отменена". Это действие увидит администратор.
              </p>
              
              <div class="mt-6 flex flex-wrap justify-end gap-3">
                <button type="button" class="btn btn-outline" phx-click="dismiss_cancel">
                  Не отменять
                </button>
                
                <button
                  type="button"
                  class="btn btn-error"
                  phx-click="cancel_booking"
                  phx-value-id={@booking_to_cancel.id}
                >
                  Да, отменить
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </main>
    """
  end

  @impl true
  def handle_event("search", %{"lookup" => %{"phone" => phone}}, socket) do
    bookings = CustomerLookup.list_by_phone(phone)

    {:noreply,
     socket
     |> assign(:phone, phone)
     |> assign(:bookings, bookings)
     |> assign(:searched?, true)
     |> assign(:booking_to_cancel, nil)
     |> assign(:notice, nil)
     |> assign(:error, nil)
     |> assign(:form, to_form(%{"phone" => phone}, as: :lookup))}
  end

  def handle_event("request_cancel", %{"id" => id}, socket) do
    booking =
      Enum.find(socket.assigns.bookings, fn booking ->
        booking.id == String.to_integer(id)
      end)

    {:noreply, assign(socket, :booking_to_cancel, booking)}
  end

  def handle_event("dismiss_cancel", _params, socket) do
    {:noreply, assign(socket, :booking_to_cancel, nil)}
  end

  def handle_event("cancel_booking", %{"id" => id}, socket) do
    case CustomerLookup.cancel_by_phone(id, socket.assigns.phone) do
      {:ok, _booking} ->
        bookings = CustomerLookup.list_by_phone(socket.assigns.phone)

        {:noreply,
         socket
         |> assign(:bookings, bookings)
         |> assign(:booking_to_cancel, nil)
         |> assign(:notice, "Запись отменена")
         |> assign(:error, nil)}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> assign(:booking_to_cancel, nil)
         |> assign(:notice, nil)
         |> assign(:error, "Запись не найдена для указанного телефона")}

      {:error, :already_cancelled} ->
        {:noreply,
         socket
         |> assign(:booking_to_cancel, nil)
         |> assign(:notice, nil)
         |> assign(:error, "Эта запись уже отменена")}

      {:error, :not_cancellable} ->
        {:noreply,
         socket
         |> assign(:booking_to_cancel, nil)
         |> assign(:notice, nil)
         |> assign(:error, "Эту запись нельзя отменить")}
    end
  end

  defp service_name(%{service: %{name: name}}) when is_binary(name), do: name
  defp service_name(_booking), do: "Услуга"

  defp format_datetime(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%d.%m.%Y %H:%M")
  end

  defp format_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_naive()
    |> Calendar.strftime("%d.%m.%Y %H:%M")
  end

  defp format_datetime(_datetime), do: "—"

  defp status_label("pending"), do: "Ожидает"
  defp status_label("confirmed"), do: "Подтверждена"
  defp status_label("cancelled"), do: "Отменена"
  defp status_label(status), do: status

  defp status_class("pending"), do: "badge badge-warning"
  defp status_class("confirmed"), do: "badge badge-success"
  defp status_class("cancelled"), do: "badge badge-neutral"
  defp status_class(_status), do: "badge badge-outline"
end
