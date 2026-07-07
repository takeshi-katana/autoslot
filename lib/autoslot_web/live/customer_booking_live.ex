defmodule AutoslotWeb.CustomerBookingLive do
  use AutoslotWeb, :live_view

  alias Autoslot.Bookings
  alias Autoslot.Scheduling
  alias Autoslot.Services

  @field_labels %{
    customer_name: "Имя клиента",
    phone: "Телефон",
    vehicle_plate: "Номер автомобиля",
    starts_at: "Время начала",
    ends_at: "Время окончания",
    status: "Статус",
    service_id: "Услуга"
  }

  @error_messages %{
    "can't be blank" => "не может быть пустым",
    "is invalid" => "имеет неверный формат",
    "has already been taken" => "уже используется",
    "does not exist" => "не найдена",
    "must be accepted" => "должно быть принято",
    "has invalid format" => "имеет неверный формат",
    "has an invalid entry" => "содержит неверное значение",
    "is reserved" => "зарезервировано",
    "does not match confirmation" => "не совпадает с подтверждением",
    "is still associated with this entry" => "связано с этой записью",
    "are still associated with this entry" => "связаны с этой записью",
    "should be at least %{count} character(s)" => "должно содержать минимум %{count} символов",
    "should be at most %{count} character(s)" => "должно содержать максимум %{count} символов",
    "should be %{count} character(s)" => "должно содержать %{count} символов",
    "should have at least %{count} item(s)" => "должно содержать минимум %{count} элемент(ов)",
    "should have at most %{count} item(s)" => "должно содержать максимум %{count} элемент(ов)",
    "should have %{count} item(s)" => "должно содержать %{count} элемент(ов)",
    "must be less than %{number}" => "должно быть меньше %{number}",
    "must be greater than %{number}" => "должно быть больше %{number}",
    "must be less than or equal to %{number}" => "должно быть меньше или равно %{number}",
    "must be greater than or equal to %{number}" => "должно быть больше или равно %{number}",
    "must be equal to %{number}" => "должно быть равно %{number}"
  }

  @workday_start ~T[09:00:00]
  @workday_end ~T[18:00:00]
  @slot_step_minutes 30

  @impl true
  def mount(_params, _session, socket) do
    services = Services.list_services()
    selected_service = List.first(services)
    selected_date = Date.utc_today()

    slot_state = load_slot_state(selected_date, selected_service)

    socket =
      socket
      |> assign(:page_title, "Онлайн-запись")
      |> assign(:services, services)
      |> assign(:selected_service, selected_service)
      |> assign(:selected_service_id, selected_service_id(selected_service))
      |> assign(:selected_date, Date.to_iso8601(selected_date))
      |> assign(:today, Date.to_iso8601(selected_date))
      |> assign(:slots, slot_state.available_slots)
      |> assign(:slot_options, slot_state.slot_options)
      |> assign(:selected_slot, selected_slot_value(List.first(slot_state.available_slots)))
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

    slot_state = load_slot_state(date, service)

    socket =
      socket
      |> assign(:selected_service, service)
      |> assign(:selected_service_id, selected_service_id)
      |> assign(:selected_date, normalized_date)
      |> assign(:slots, slot_state.available_slots)
      |> assign(:slot_options, slot_state.slot_options)
      |> assign(:selected_slot, selected_slot_value(List.first(slot_state.available_slots)))
      |> assign(:success_message, nil)
      |> assign(:error_message, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_slot", %{"slot" => slot_value}, socket) do
    selected_slot = find_slot(socket.assigns.slots, slot_value)

    if selected_slot do
      {:noreply, assign(socket, :selected_slot, selected_slot_value(selected_slot))}
    else
      {:noreply, socket}
    end
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
            slot_state = load_slot_state(date, service)

            socket =
              socket
              |> assign(:slots, slot_state.available_slots)
              |> assign(:slot_options, slot_state.slot_options)
              |> assign(
                :selected_slot,
                selected_slot_value(List.first(slot_state.available_slots))
              )
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

  defp load_slot_state(_date, nil), do: %{available_slots: [], slot_options: []}

  defp load_slot_state(%Date{} = date, service) do
    bookings = Bookings.list_active_bookings_for_date(date)
    available_slots = Scheduling.available_slots(date, service, bookings)
    available_starts = MapSet.new(available_slots, &slot_value/1)

    slot_options =
      date
      |> build_day_slots(service)
      |> Enum.map(fn slot ->
        Map.put(slot, :available, MapSet.member?(available_starts, slot_value(slot)))
      end)

    %{available_slots: available_slots, slot_options: slot_options}
  end

  defp build_day_slots(%Date{} = date, service) do
    starts_at = DateTime.new!(date, @workday_start, "Etc/UTC")
    workday_ends_at = DateTime.new!(date, @workday_end, "Etc/UTC")
    duration_seconds = service.duration_minutes * 60
    step_seconds = @slot_step_minutes * 60

    do_build_day_slots(starts_at, workday_ends_at, duration_seconds, step_seconds, [])
  end

  defp do_build_day_slots(starts_at, workday_ends_at, duration_seconds, step_seconds, acc) do
    ends_at = DateTime.add(starts_at, duration_seconds, :second)

    if DateTime.compare(ends_at, workday_ends_at) in [:lt, :eq] do
      slot = %{starts_at: starts_at, ends_at: ends_at}
      next_starts_at = DateTime.add(starts_at, step_seconds, :second)

      do_build_day_slots(next_starts_at, workday_ends_at, duration_seconds, step_seconds, [
        slot | acc
      ])
    else
      Enum.reverse(acc)
    end
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
  defp selected_slot_value(slot), do: slot_value(slot)

  defp slot_value(slot) do
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
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      message
      |> translate_error_message()
      |> interpolate_error_message(opts)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        "#{field_label(field)}: #{message}"
      end)
    end)
    |> Enum.join(", ")
  end

  defp translate_error_message(message) do
    Map.get(@error_messages, message, message)
  end

  defp interpolate_error_message(message, opts) do
    Enum.reduce(opts, message, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp field_label(field) do
    Map.get(@field_labels, field, field |> Atom.to_string() |> String.replace("_", " "))
  end

  defp slot_button_class(%{available: false}, _selected_slot) do
    "rounded-xl border border-base-300 bg-base-300/40 px-4 py-1 text-left text-base-content/35 cursor-not-allowed"
  end

  defp slot_button_class(slot, selected_slot) do
    base = "rounded-xl border px-4 py-1 text-left transition hover:-translate-y-0.5"

    if selected_slot == slot_value(slot) do
      "#{base} border-primary bg-primary text-primary-content shadow"
    else
      "#{base} border-base-300 bg-base-100 text-base-content hover:border-primary hover:bg-base-200"
    end
  end

  defp slot_status_label(%{available: false}), do: "Занято"
  defp slot_status_label(_slot), do: "Свободно"

  defp slot_status_class(%{available: false}), do: "text-xs text-base-content/35"
  defp slot_status_class(_slot), do: "text-xs text-base-content/60"

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-transparent px-6 py-10">
      <div class="mx-auto max-w-5xl">
        <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <a href="/" class="text-sm text-primary hover:underline">← На главную</a>
            <h1 class="mt-4 text-4xl font-semibold text-base-content">
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
          <div class="grid gap-6 lg:grid-cols-[1fr_390px]">
            <section class="rounded-3xl border border-white/10 bg-base-100/80 p-6 shadow-2xl backdrop-blur-xl">
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
                <input type="hidden" name="slot" value={@selected_slot} />
                <div class="rounded-2xl border border-white/10 bg-base-200/70 p-4">
                  <div class="text-sm text-base-content/60">Выбранное время</div>

                  <div class="mt-1 text-lg font-semibold">
                    <%= if @selected_slot do %>
                      {format_slot(find_slot(@slots, @selected_slot))}
                    <% else %>
                      Нет доступного времени
                    <% end %>
                  </div>
                </div>

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

                <button type="submit" class="btn btn-primary mt-2" disabled={is_nil(@selected_slot)}>
                  Создать запись
                </button>
                <div class="mt-10 flex justify-center">
                  <div class="relative w-full max-w-[420px]">
                    <div class="absolute inset-0 rounded-[3rem] bg-primary/5 blur-3xl"></div>

                    <img
                      src={~p"/images/booking-illustration.svg"}
                      alt="Иллюстрация автосервиса"
                      class="relative mx-auto w-full max-w-[480px] select-none opacity-65"
                      style="filter: hue-rotate(230deg) saturate(0.55) brightness(0.72) contrast(1.25);"
                      draggable="false"
                    />
                  </div>
                </div>
              </form>
            </section>

            <aside class="grid gap-6">
              <section class="rounded-3xl border border-white/10 bg-base-100/80 p-6 shadow-2xl backdrop-blur-xl">
                <h2 class="text-xl font-semibold">Выбранная услуга</h2>

                <%= if @selected_service do %>
                  <div class="mt-4 rounded-2xl border border-white/10 bg-base-200/50 p-4">
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

              <section class="rounded-3xl border border-white/10 bg-base-100/80 p-6 shadow-2xl backdrop-blur-xl">
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <h2 class="text-xl font-semibold">Доступные слоты</h2>

                    <p class="mt-2 text-sm text-base-content/70">
                      Выберите свободный интервал. Занятые слоты показаны серым цветом.
                    </p>
                  </div>
                </div>

                <div class="mt-4 flex flex-wrap gap-2 text-xs">
                  <span class="rounded-full bg-base-100/70 px-3 py-1 text-base-content">
                    Свободно
                  </span>

                  <span class="rounded-full bg-primary px-3 py-1 text-primary-content">
                    Выбрано
                  </span>

                  <span class="rounded-full bg-base-300 px-3 py-1 text-base-content/40">
                    Занято
                  </span>
                </div>

                <div class="mt-5 grid grid-cols-2 gap-3">
                  <%= for slot <- @slot_options do %>
                    <button
                      type="button"
                      disabled={!slot.available}
                      phx-click={if slot.available, do: "select_slot", else: nil}
                      phx-value-slot={slot_value(slot)}
                      class={slot_button_class(slot, @selected_slot)}
                    >
                      <div class="font-semibold">{format_slot(slot)}</div>

                      <div class={slot_status_class(slot)}>{slot_status_label(slot)}</div>
                    </button>
                  <% end %>
                </div>

                <div class="mt-6 rounded-2xl border border-white/10 bg-base-200/70 p-4 text-sm text-base-content/70">
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
