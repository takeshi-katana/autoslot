defmodule AutoslotWeb.CustomerBookingLive do
  use AutoslotWeb, :live_view

  alias Autoslot.Bookings
  alias Autoslot.Scheduling
  alias Autoslot.Services

  @impl true
  def mount(_params, _session, socket) do
    services = Services.list_services()
    selected_service = List.first(services)
    selected_date = Date.utc_today()

    slots = load_available_slots(selected_date, selected_service)

    socket =
      socket
      |> assign(:page_title, "Онлайн-запись")
      |> assign(:services, services)
      |> assign(:selected_service, selected_service)
      |> assign(:selected_service_id, selected_service_id(selected_service))
      |> assign(:selected_date, Date.to_iso8601(selected_date))
      |> assign(:today, Date.to_iso8601(selected_date))
      |> assign(:slots, slots)
      |> assign(:selected_slot, selected_slot_value(List.first(slots)))
      |> assign(:customer_name, "")
      |> assign(:phone, "")
      |> assign(:vehicle_plate, "")
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("change_selection", params, socket) do
    selected_service_id = Map.get(params, "service_id", socket.assigns.selected_service_id)
    selected_date = Map.get(params, "date", socket.assigns.selected_date)

    service = find_service(socket.assigns.services, selected_service_id)
    date = parse_booking_date(selected_date)
    normalized_date = Date.to_iso8601(date)

    slots = load_available_slots(date, service)

    socket =
      socket
      |> assign(:selected_service, service)
      |> assign(:selected_service_id, selected_service_id)
      |> assign(:selected_date, normalized_date)
      |> assign(:slots, slots)
      |> assign(:selected_slot, selected_slot_value(List.first(slots)))
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_booking", params, socket) do
    service = find_service(socket.assigns.services, params["service_id"])
    selected_slot = find_slot(socket.assigns.slots, params["slot"])

    case {service, selected_slot} do
      {nil, _slot} ->
        {:noreply, assign(socket, :error_message, "Выберите услугу.")}

      {_service, nil} ->
        {:noreply, assign(socket, :error_message, "Выберите доступное время.")}

      {service, slot} ->
        attrs = %{
          customer_name: params["customer_name"],
          phone: params["phone"],
          vehicle_plate: params["vehicle_plate"],
          starts_at: slot.starts_at,
          ends_at: slot.ends_at,
          status: "pending",
          service_id: service.id
        }

        case Bookings.create_booking(attrs) do
          {:ok, _booking} ->
            date = parse_booking_date(socket.assigns.selected_date)
            updated_slots = load_available_slots(date, service)

            socket =
              socket
              |> assign(:slots, updated_slots)
              |> assign(:selected_slot, selected_slot_value(List.first(updated_slots)))
              |> assign(:customer_name, "")
              |> assign(:phone, "")
              |> assign(:vehicle_plate, "")
              |> assign(:success_message, "Запись успешно создана.")
              |> assign(:error_message, nil)

            {:noreply, socket}

          {:error, changeset} ->
            {:noreply,
             assign(socket,
               success_message: nil,
               error_message: format_changeset_errors(changeset)
             )}
        end
    end
  end

  defp load_available_slots(_date, nil), do: []

  defp load_available_slots(%Date{} = date, service) do
    bookings = Bookings.list_active_bookings_for_date(date)
    Scheduling.available_slots(date, service, bookings)
  end

  defp selected_service_id(nil), do: nil
  defp selected_service_id(service), do: Integer.to_string(service.id)

  defp parse_booking_date(date_string) do
    date = parse_date(date_string)
    today = Date.utc_today()

    case Date.compare(date, today) do
      :lt -> today
      _ -> date
    end
  end

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _reason} -> Date.utc_today()
    end
  end

  defp find_service(_services, nil), do: nil

  defp find_service(services, service_id) do
    Enum.find(services, fn service ->
      Integer.to_string(service.id) == service_id
    end)
  end

  defp selected_slot_value(nil), do: nil

  defp selected_slot_value(slot) do
    DateTime.to_iso8601(slot.starts_at)
  end

  defp find_slot(_slots, nil), do: nil

  defp find_slot(slots, slot_value) do
    Enum.find(slots, fn slot ->
      DateTime.to_iso8601(slot.starts_at) == slot_value
    end)
  end

  defp format_time(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0, 5)
  end

  defp format_slot(slot) do
    "#{format_time(slot.starts_at)}–#{format_time(slot.ends_at)}"
  end

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
      <div class="mx-auto max-w-5xl">
        <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <a href="/" class="text-sm text-primary hover:underline">← На главную</a>
            <h1 class="mt-4 text-4xl font-bold text-base-content">
              Онлайн-запись в автосервис
            </h1>
            
            <p class="mt-3 max-w-2xl text-base-content/70">
              Выберите услугу, дату и свободное время. После отправки формы запись будет создана
              со статусом ожидания подтверждения.
            </p>
          </div>
          
          <a href="/my-bookings" class="btn btn-outline">
            Мои записи
          </a>
        </div>
        
        <%= if Enum.empty?(@services) do %>
          <div class="rounded-lg border border-warning bg-warning/10 p-6">
            <h2 class="text-xl font-semibold">Услуги пока не добавлены</h2>
            
            <p class="mt-2">
              Сначала добавьте услуги в каталог или запустите seed-данные.
            </p>
          </div>
        <% else %>
          <div class="grid gap-6 lg:grid-cols-[1fr_360px]">
            <section class="rounded-xl bg-base-100 p-6 shadow">
              <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <h2 class="text-2xl font-semibold">Данные записи</h2>
                  
                  <p class="mt-2 text-sm text-base-content/60">
                    Заполните контактные данные и выберите подходящий слот.
                  </p>
                </div>
                
                <a href="/my-bookings" class="btn btn-outline btn-sm">
                  Проверить запись
                </a>
              </div>
              
              <%= if @success_message do %>
                <div class="mt-4 rounded-lg border border-success bg-success/10 p-4 text-success">
                  {@success_message}
                  <div class="mt-3">
                    <a href="/my-bookings" class="btn btn-success btn-sm">
                      Перейти к моим записям
                    </a>
                  </div>
                </div>
              <% end %>
              
              <%= if @error_message do %>
                <div class="mt-4 rounded-lg border border-error bg-error/10 p-4 text-error">
                  {@error_message}
                </div>
              <% end %>
              
              <form phx-change="change_selection" class="mt-6 grid gap-4">
                <label class="grid gap-2">
                  <span class="font-medium">Услуга</span>
                  <select name="service_id" class="select select-bordered w-full">
                    <%= for service <- @services do %>
                      <option
                        value={service.id}
                        selected={Integer.to_string(service.id) == @selected_service_id}
                      >
                        {service.name} — {service.duration_minutes} мин.
                      </option>
                    <% end %>
                  </select>
                </label>
                
                <label class="grid gap-2">
                  <span class="font-medium">Дата</span>
                  <input
                    type="date"
                    name="date"
                    value={@selected_date}
                    min={@today}
                    class="input input-bordered w-full"
                  />
                  <span class="text-xs text-base-content/50">
                    Запись доступна с сегодняшней даты.
                  </span>
                </label>
              </form>
              
              <form phx-submit="create_booking" class="mt-6 grid gap-4">
                <input type="hidden" name="service_id" value={@selected_service_id} />
                <label class="grid gap-2">
                  <span class="font-medium">Свободное время</span>
                  <%= if Enum.empty?(@slots) do %>
                    <div class="rounded-lg border border-warning bg-warning/10 p-4">
                      На выбранную дату нет доступных слотов.
                    </div>
                  <% else %>
                    <select name="slot" class="select select-bordered w-full">
                      <%= for slot <- @slots do %>
                        <option value={DateTime.to_iso8601(slot.starts_at)}>
                          {format_slot(slot)}
                        </option>
                      <% end %>
                    </select>
                  <% end %>
                </label>
                
                <label class="grid gap-2">
                  <span class="font-medium">Имя клиента</span>
                  <input
                    type="text"
                    name="customer_name"
                    value={@customer_name}
                    placeholder="Иван Петров"
                    class="input input-bordered w-full"
                  />
                </label>
                
                <label class="grid gap-2">
                  <span class="font-medium">Телефон</span>
                  <input
                    type="text"
                    name="phone"
                    value={@phone}
                    placeholder="+7 999 123-45-67"
                    class="input input-bordered w-full"
                  />
                </label>
                
                <label class="grid gap-2">
                  <span class="font-medium">Номер автомобиля</span>
                  <input
                    type="text"
                    name="vehicle_plate"
                    value={@vehicle_plate}
                    placeholder="А123ВС125"
                    class="input input-bordered w-full"
                  />
                </label>
                
                <button type="submit" class="btn btn-primary mt-2" disabled={Enum.empty?(@slots)}>
                  Создать запись
                </button>
              </form>
            </section>
            
            <aside class="grid gap-6">
              <section class="rounded-xl bg-base-100 p-6 shadow">
                <h2 class="text-xl font-semibold">Выбранная услуга</h2>
                
                <%= if @selected_service do %>
                  <div class="mt-4 rounded-xl border border-base-300 p-4">
                    <h3 class="text-2xl font-bold text-base-content">
                      {@selected_service.name}
                    </h3>
                    
                    <div class="mt-3 flex flex-wrap gap-2">
                      <span class="badge badge-primary">
                        {@selected_service.duration_minutes} мин.
                      </span>
                      
                      <span class="badge badge-outline">
                        {@selected_service.price} ₽
                      </span>
                    </div>
                    
                    <p class="mt-4 text-sm leading-6 text-base-content/70">
                      {@selected_service.description}
                    </p>
                  </div>
                <% else %>
                  <p class="mt-3 text-sm text-base-content/60">
                    Выберите услугу, чтобы увидеть подробности.
                  </p>
                <% end %>
              </section>
              
              <section class="rounded-xl bg-base-100 p-6 shadow">
                <h2 class="text-xl font-semibold">Доступные слоты</h2>
                
                <p class="mt-2 text-sm text-base-content/70">
                  Система показывает только те интервалы, которые не пересекаются с активными
                  записями.
                </p>
                
                <div class="mt-5 grid gap-2">
                  <%= for slot <- @slots do %>
                    <div class="rounded-lg border border-base-300 px-4 py-3">
                      {format_slot(slot)}
                    </div>
                  <% end %>
                </div>
                
                <div class="mt-6 rounded-xl bg-base-200 p-4 text-sm text-base-content/70">
                  <div class="font-semibold text-base-content">Уже записывались?</div>
                  
                  <p class="mt-1">
                    Найдите свои записи по номеру телефона и проверьте статус заявки.
                  </p>
                  
                  <a href="/my-bookings" class="btn btn-outline btn-sm mt-4">
                    Мои записи
                  </a>
                </div>
              </section>
            </aside>
          </div>
        <% end %>
      </div>
    </main>
    """
  end
end
