defmodule AutoslotWeb.AdminBookingLive do
  use AutoslotWeb, :live_view

  alias Autoslot.Bookings

  @statuses ["pending", "confirmed", "cancelled"]

  @impl true
  def mount(_params, _session, socket) do
    selected_date = Date.utc_today()
    bookings = Bookings.list_bookings_with_services_for_date(selected_date)

    socket =
      socket
      |> assign(:page_title, "Управление записями")
      |> assign(:selected_date, Date.to_iso8601(selected_date))
      |> assign(:bookings, bookings)
      |> assign(:statuses, @statuses)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_date", %{"date" => date_string}, socket) do
    selected_date = parse_date(date_string)
    bookings = Bookings.list_bookings_with_services_for_date(selected_date)

    socket =
      socket
      |> assign(:selected_date, Date.to_iso8601(selected_date))
      |> assign(:bookings, bookings)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_status", %{"booking_id" => booking_id, "status" => status}, socket) do
    booking = Bookings.get_booking!(booking_id)

    case Bookings.update_booking(booking, %{status: status}) do
      {:ok, _booking} ->
        selected_date = parse_date(socket.assigns.selected_date)
        bookings = Bookings.list_bookings_with_services_for_date(selected_date)

        socket =
          socket
          |> assign(:bookings, bookings)
          |> assign(:success_message, "Статус записи обновлен.")
          |> assign(:error_message, nil)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:success_message, nil)
          |> assign(:error_message, format_changeset_errors(changeset))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("confirm_booking", %{"id" => booking_id}, socket) do
    update_status(socket, booking_id, "confirmed", "Запись подтверждена.")
  end

  @impl true
  def handle_event("cancel_booking", %{"id" => booking_id}, socket) do
    update_status(socket, booking_id, "cancelled", "Запись отменена.")
  end

  defp update_status(socket, booking_id, status, message) do
    booking = Bookings.get_booking!(booking_id)

    case Bookings.update_booking(booking, %{status: status}) do
      {:ok, _} ->
        selected_date = parse_date(socket.assigns.selected_date)
        bookings = Bookings.list_bookings_with_services_for_date(selected_date)

        {:noreply,
         socket
         |> assign(:bookings, bookings)
         |> assign(:success_message, message)
         |> assign(:error_message, nil)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:success_message, nil)
         |> assign(:error_message, format_changeset_errors(changeset))}
    end
  end

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _reason} -> Date.utc_today()
    end
  end

  defp format_datetime(%DateTime{} = datetime) do
    date = Date.to_iso8601(DateTime.to_date(datetime))

    time =
      datetime
      |> DateTime.to_time()
      |> Time.to_string()
      |> String.slice(0, 5)

    "#{date} #{time}"
  end

  defp format_time_range(booking) do
    start_time =
      booking.starts_at
      |> DateTime.to_time()
      |> Time.to_string()
      |> String.slice(0, 5)

    end_time =
      booking.ends_at
      |> DateTime.to_time()
      |> Time.to_string()
      |> String.slice(0, 5)

    "#{start_time}–#{end_time}"
  end

  defp service_name(%{service: %{name: name}}) when is_binary(name), do: name
  defp service_name(_booking), do: "—"

  defp status_label("pending"), do: "Ожидает"
  defp status_label("confirmed"), do: "Подтверждена"
  defp status_label("cancelled"), do: "Отменена"
  defp status_label(status), do: status

  defp status_badge_class("pending"), do: "badge badge-warning"
  defp status_badge_class("confirmed"), do: "badge badge-success"
  defp status_badge_class("cancelled"), do: "badge badge-error"
  defp status_badge_class(_status), do: "badge"

  defp format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, _opts} -> message end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message -> "#{field}: #{message}" end)
    end)
    |> Enum.join(", ")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-6 py-10">
      <div class="mx-auto max-w-7xl">
        <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <a href="/" class="text-sm text-primary hover:underline">← На главную</a>
            <h1 class="mt-4 text-4xl font-bold text-base-content">
              Управление записями
            </h1>
            
            <p class="mt-3 max-w-2xl text-base-content/70">
              Административная страница для просмотра записей клиентов и изменения их статусов.
            </p>
          </div>
          
          <div class="flex gap-3">
            <a href="/book" class="btn btn-outline">Страница клиента</a>
            <a href="/services" class="btn btn-outline">Каталог услуг</a>
          </div>
        </div>
        
        <section class="rounded-xl bg-base-100 p-6 shadow">
          <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <form phx-change="change_date" class="flex flex-col gap-2 sm:flex-row sm:items-end">
              <label class="grid gap-2">
                <span class="font-medium">Дата</span>
                <input
                  type="date"
                  name="date"
                  value={@selected_date}
                  class="input input-bordered"
                />
              </label>
            </form>
            
            <div class="text-sm text-base-content/60">
              Найдено записей: {length(@bookings)}
            </div>
          </div>
          
          <%= if @success_message do %>
            <div class="mt-4 rounded-lg border border-success bg-success/10 p-4 text-success">
              {@success_message}
            </div>
          <% end %>
          
          <%= if @error_message do %>
            <div class="mt-4 rounded-lg border border-error bg-error/10 p-4 text-error">
              {@error_message}
            </div>
          <% end %>
          
          <%= if Enum.empty?(@bookings) do %>
            <div class="mt-8 rounded-lg border border-base-300 p-8 text-center">
              <h2 class="text-xl font-semibold">На выбранную дату записей нет</h2>
              
              <p class="mt-2 text-base-content/60">
                Создайте тестовую запись на странице клиента.
              </p>
               <a href="/book" class="btn btn-primary mt-4">Создать запись</a>
            </div>
          <% else %>
            <div class="mt-6 overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Время</th>
                    
                    <th>Клиент</th>
                    
                    <th>Телефон</th>
                    
                    <th>Автомобиль</th>
                    
                    <th>Услуга</th>
                    
                    <th>Статус</th>
                    
                    <th>Изменить статус</th>
                    
                    <th>Создана</th>
                  </tr>
                </thead>
                
                <tbody>
                  <%= for booking <- @bookings do %>
                    <tr>
                      <td class="font-medium">
                        {format_time_range(booking)}
                      </td>
                      
                      <td>
                        {booking.customer_name}
                      </td>
                      
                      <td>
                        {booking.phone}
                      </td>
                      
                      <td>
                        {booking.vehicle_plate}
                      </td>
                      
                      <td>
                        {service_name(booking)}
                      </td>
                      
                      <td>
                        <span class={status_badge_class(booking.status)}>
                          {status_label(booking.status)}
                        </span>
                      </td>
                      
                      <td>
                        <div class="flex gap-2">
                          <%= if booking.status == "pending" do %>
                            <button
                              phx-click="confirm_booking"
                              phx-value-id={booking.id}
                              class="btn btn-success btn-sm"
                            >
                              Подтвердить
                            </button>
                          <% end %>
                          
                          <%= if booking.status != "cancelled" do %>
                            <button
                              phx-click="cancel_booking"
                              phx-value-id={booking.id}
                              class="btn btn-error btn-sm"
                            >
                              Отменить
                            </button>
                          <% end %>
                        </div>
                      </td>
                      
                      <td class="text-sm text-base-content/60">
                        {format_datetime(booking.inserted_at)}
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </section>
      </div>
    </main>
    """
  end
end
