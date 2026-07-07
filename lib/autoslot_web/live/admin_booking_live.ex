defmodule AutoslotWeb.AdminBookingLive do
  use AutoslotWeb, :live_view

  alias Autoslot.Bookings

  @status_filters [
    {"all", "Все"},
    {"pending", "Ожидает"},
    {"confirmed", "Подтверждена"},
    {"cancelled", "Отменена"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    selected_date = Date.utc_today()
    selected_status = "all"
    search_query = ""
    {bookings, summary} = load_admin_data(selected_date, selected_status, search_query)

    socket =
      socket
      |> assign(:page_title, "Управление записями")
      |> assign(:selected_date, Date.to_iso8601(selected_date))
      |> assign(:selected_status, selected_status)
      |> assign(:search_query, search_query)
      |> assign(:status_filters, @status_filters)
      |> assign(:bookings, bookings)
      |> assign(:summary, summary)
      |> assign(:booking_to_cancel, nil)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_date", %{"date" => date_string}, socket) do
    selected_date = parse_date(date_string)

    {bookings, summary} =
      load_admin_data(
        selected_date,
        socket.assigns.selected_status,
        socket.assigns.search_query
      )

    socket =
      socket
      |> assign(:selected_date, Date.to_iso8601(selected_date))
      |> assign(:bookings, bookings)
      |> assign(:summary, summary)
      |> assign(:booking_to_cancel, nil)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_status_filter", %{"status" => selected_status}, socket) do
    selected_date = parse_date(socket.assigns.selected_date)
    selected_status = normalize_status_filter(selected_status)

    {bookings, summary} =
      load_admin_data(
        selected_date,
        selected_status,
        socket.assigns.search_query
      )

    socket =
      socket
      |> assign(:selected_status, selected_status)
      |> assign(:bookings, bookings)
      |> assign(:summary, summary)
      |> assign(:booking_to_cancel, nil)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search_bookings", %{"search_query" => search_query}, socket) do
    selected_date = parse_date(socket.assigns.selected_date)
    search_query = String.trim(search_query)

    {bookings, summary} =
      load_admin_data(
        selected_date,
        socket.assigns.selected_status,
        search_query
      )

    socket =
      socket
      |> assign(:search_query, search_query)
      |> assign(:bookings, bookings)
      |> assign(:summary, summary)
      |> assign(:booking_to_cancel, nil)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    selected_date = parse_date(socket.assigns.selected_date)
    search_query = ""

    {bookings, summary} =
      load_admin_data(
        selected_date,
        socket.assigns.selected_status,
        search_query
      )

    socket =
      socket
      |> assign(:search_query, search_query)
      |> assign(:bookings, bookings)
      |> assign(:summary, summary)
      |> assign(:booking_to_cancel, nil)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("confirm_booking", %{"id" => booking_id}, socket) do
    update_booking_status(socket, booking_id, "confirmed", "Запись подтверждена.")
  end

  @impl true
  def handle_event("request_cancel_booking", %{"id" => booking_id}, socket) do
    booking_to_cancel =
      Enum.find(socket.assigns.bookings, fn booking ->
        Integer.to_string(booking.id) == booking_id
      end)

    socket =
      socket
      |> assign(:booking_to_cancel, booking_to_cancel)
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("dismiss_cancel_booking", _params, socket) do
    {:noreply, assign(socket, :booking_to_cancel, nil)}
  end

  @impl true
  def handle_event("cancel_booking", %{"id" => booking_id}, socket) do
    update_booking_status(socket, booking_id, "cancelled", "Запись отменена.")
  end

  defp update_booking_status(socket, booking_id, status, success_message) do
    booking = Bookings.get_booking!(booking_id)

    case Bookings.update_booking(booking, %{status: status}) do
      {:ok, _booking} ->
        selected_date = parse_date(socket.assigns.selected_date)

        {bookings, summary} =
          load_admin_data(
            selected_date,
            socket.assigns.selected_status,
            socket.assigns.search_query
          )

        socket =
          socket
          |> assign(:bookings, bookings)
          |> assign(:summary, summary)
          |> assign(:booking_to_cancel, nil)
          |> assign(:success_message, success_message)
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

  defp load_admin_data(%Date{} = date, selected_status, search_query) do
    all_bookings = Bookings.list_bookings_with_services_for_date(date)
    summary = build_summary(all_bookings)

    filtered_bookings =
      all_bookings
      |> filter_bookings_by_status(selected_status)
      |> filter_bookings_by_search(search_query)

    {filtered_bookings, summary}
  end

  defp filter_bookings_by_status(bookings, "all"), do: bookings

  defp filter_bookings_by_status(bookings, selected_status) do
    Enum.filter(bookings, fn booking ->
      booking.status == selected_status
    end)
  end

  defp filter_bookings_by_search(bookings, ""), do: bookings

  defp filter_bookings_by_search(bookings, search_query) do
    normalized_query = normalize_search_value(search_query)

    Enum.filter(bookings, fn booking ->
      [
        booking.customer_name,
        booking.phone,
        booking.vehicle_plate,
        service_name(booking)
      ]
      |> Enum.any?(fn value ->
        value
        |> normalize_search_value()
        |> String.contains?(normalized_query)
      end)
    end)
  end

  defp normalize_search_value(nil), do: ""

  defp normalize_search_value(value) do
    value
    |> to_string()
    |> String.downcase()
  end

  defp build_summary(bookings) do
    %{
      total: length(bookings),
      pending: count_by_status(bookings, "pending"),
      confirmed: count_by_status(bookings, "confirmed"),
      cancelled: count_by_status(bookings, "cancelled")
    }
  end

  defp count_by_status(bookings, status) do
    Enum.count(bookings, fn booking ->
      booking.status == status
    end)
  end

  defp normalize_status_filter(status) do
    allowed_statuses =
      Enum.map(@status_filters, fn {value, _label} ->
        value
      end)

    if status in allowed_statuses do
      status
    else
      "all"
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

          <div class="flex flex-wrap gap-3">
            <a href="/book" class="btn btn-outline">
              Страница клиента
            </a>

            <a href="/services" class="btn btn-outline">
              Каталог услуг
            </a>

            <a href="/admin/logout" class="btn btn-error">
              Выйти
            </a>
          </div>
        </div>

        <section class="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div class="rounded-xl bg-base-100 p-5 shadow">
            <div class="text-sm text-base-content/60">Всего записей</div>

            <div class="mt-2 text-3xl font-bold">{@summary.total}</div>
          </div>

          <div class="rounded-xl bg-base-100 p-5 shadow">
            <div class="text-sm text-base-content/60">Ожидают</div>

            <div class="mt-2 text-3xl font-bold text-warning">{@summary.pending}</div>
          </div>

          <div class="rounded-xl bg-base-100 p-5 shadow">
            <div class="text-sm text-base-content/60">Подтверждены</div>

            <div class="mt-2 text-3xl font-bold text-success">{@summary.confirmed}</div>
          </div>

          <div class="rounded-xl bg-base-100 p-5 shadow">
            <div class="text-sm text-base-content/60">Отменены</div>

            <div class="mt-2 text-3xl font-bold text-error">{@summary.cancelled}</div>
          </div>
        </section>

        <section class="rounded-xl bg-base-100 p-6 shadow">
          <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <div class="flex flex-col gap-4 sm:flex-row sm:items-end">
              <form phx-change="change_date" class="flex flex-col gap-2">
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

              <form phx-change="change_status_filter" class="flex flex-col gap-2">
                <label class="grid gap-2">
                  <span class="font-medium">Статус</span>
                  <select name="status" class="select select-bordered">
                    <%= for {status, label} <- @status_filters do %>
                      <option value={status} selected={@selected_status == status}>
                        {label}
                      </option>
                    <% end %>
                  </select>
                </label>
              </form>

              <form
                phx-change="search_bookings"
                phx-submit="search_bookings"
                class="flex flex-col gap-2"
              >
                <label class="grid gap-2">
                  <span class="font-medium">Поиск</span>
                  <div class="flex gap-2">
                    <input
                      type="text"
                      name="search_query"
                      value={@search_query}
                      placeholder="Клиент, телефон, авто или услуга"
                      class="input input-bordered w-80 max-w-full"
                    />
                    <%= if @search_query != "" do %>
                      <button
                        type="button"
                        phx-click="clear_search"
                        class="btn btn-outline"
                      >
                        Очистить
                      </button>
                    <% end %>
                  </div>
                </label>
              </form>
            </div>

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
                Измените дату, фильтр статуса или поисковый запрос. Также можно создать тестовую запись на странице клиента.
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

                    <th>Действия</th>

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
                              phx-click="request_cancel_booking"
                              phx-value-id={booking.id}
                              class="btn btn-error btn-sm"
                            >
                              Отменить
                            </button>
                          <% else %>
                            <span class="text-sm text-base-content/50">Нет действий</span>
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

      <%= if @booking_to_cancel do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div class="w-full max-w-lg rounded-xl bg-base-100 p-6 shadow-xl">
            <h2 class="text-2xl font-bold text-base-content">
              Отменить запись?
            </h2>

            <p class="mt-3 text-base-content/70">
              Вы действительно хотите отменить запись клиента?
            </p>

            <div class="mt-5 rounded-lg border border-base-300 bg-base-200 p-4">
              <div class="grid gap-2 text-sm">
                <div>
                  <span class="font-semibold">Клиент:</span> {@booking_to_cancel.customer_name}
                </div>

                <div>
                  <span class="font-semibold">Телефон:</span> {@booking_to_cancel.phone}
                </div>

                <div>
                  <span class="font-semibold">Автомобиль:</span> {@booking_to_cancel.vehicle_plate}
                </div>

                <div>
                  <span class="font-semibold">Услуга:</span> {service_name(@booking_to_cancel)}
                </div>

                <div>
                  <span class="font-semibold">Время:</span> {format_time_range(@booking_to_cancel)}
                </div>
              </div>
            </div>

            <div class="mt-6 flex justify-end gap-3">
              <button phx-click="dismiss_cancel_booking" class="btn btn-outline">
                Нет, оставить
              </button>

              <button
                phx-click="cancel_booking"
                phx-value-id={@booking_to_cancel.id}
                class="btn btn-error"
              >
                Да, отменить
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </main>
    """
  end
end
