defmodule AutoslotWeb.CustomerCameraLive do
  use AutoslotWeb, :live_view

  @camera_boxes [
    %{
      id: "bay-1",
      title: "Бокс 1",
      subtitle: "Диагностика автомобиля",
      status: "Идёт работа",
      vehicle_hint: "Осмотр, компьютерная диагностика, проверка ошибок",
      demo_url: "https://vladlink.ru/city-cams-vdk/"
    },
    %{
      id: "bay-2",
      title: "Бокс 2",
      subtitle: "Ремонт на подъёмнике",
      status: "Свободный просмотр",
      vehicle_hint: "Подвеска, тормозная система, ходовая часть",
      demo_url: "https://vladlink.ru/city-cams-vdk/"
    },
    %{
      id: "bay-3",
      title: "Бокс 3",
      subtitle: "Электрика и обслуживание",
      status: "Онлайн",
      vehicle_hint: "Электрика, свет, АКБ, дополнительные проверки",
      demo_url: "https://vladlink.ru/city-cams-vdk/"
    },
    %{
      id: "bay-4",
      title: "Бокс 4",
      subtitle: "Быстрые работы",
      status: "Онлайн",
      vehicle_hint: "Шиномонтаж, масло, фильтры, короткие операции",
      demo_url: "https://vladlink.ru/city-cams-vdk/"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Камеры боксов")
      |> assign(:camera_boxes, @camera_boxes)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-transparent px-6 py-10 text-base-content">
      <div class="mx-auto max-w-7xl">
        <header class="mb-8 flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <a href="/" class="text-sm text-primary hover:underline">← На главную</a>

            <div class="mt-5 inline-flex items-center gap-3 rounded-full border border-primary/25 bg-primary/10 px-4 py-2 text-sm font-medium text-primary shadow-sm backdrop-blur">
              <span class="size-2 rounded-full bg-primary"></span> Клиентский доступ
            </div>

            <h1 class="mt-5 text-4xl font-semibold tracking-tight text-base-content md:text-5xl">
              Онлайн-камеры ремонтных боксов
            </h1>

            <p class="mt-4 max-w-3xl text-lg leading-8 text-base-content/70">
              Клиент может наблюдать за ходом ремонта автомобиля, если работа занимает несколько
              часов, а он не находится в комнате ожидания автосервиса.
            </p>
          </div>

          <div class="flex flex-wrap gap-3">
            <a href="/book" class="btn btn-primary">
              Записаться
            </a>

            <a href="/my-bookings" class="btn btn-outline">
              Мои записи
            </a>
          </div>
        </header>

        <section class="mb-8 grid gap-4 md:grid-cols-3">
          <div class="rounded-3xl border border-white/10 bg-base-100/80 p-5 shadow-2xl backdrop-blur-xl">
            <div class="text-sm text-base-content/55">Всего боксов</div>
            <div class="mt-2 text-3xl font-semibold">4</div>
          </div>

          <div class="rounded-3xl border border-white/10 bg-base-100/80 p-5 shadow-2xl backdrop-blur-xl">
            <div class="text-sm text-base-content/55">Формат доступа</div>
            <div class="mt-2 text-3xl font-semibold">Online</div>
          </div>

          <div class="rounded-3xl border border-white/10 bg-base-100/80 p-5 shadow-2xl backdrop-blur-xl">
            <div class="text-sm text-base-content/55">Назначение</div>
            <div class="mt-2 text-3xl font-semibold">Контроль</div>
          </div>
        </section>

        <section class="grid gap-6 lg:grid-cols-2">
          <%= for camera <- @camera_boxes do %>
            <article class="overflow-hidden rounded-[2rem] border border-white/10 bg-base-100/80 shadow-2xl backdrop-blur-xl">
              <div class="relative aspect-video overflow-hidden bg-base-300/60">
                <div class="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(99,102,241,0.25),transparent_35%),linear-gradient(135deg,rgba(15,23,42,0.9),rgba(31,41,55,0.8))]">
                </div>

                <div class="absolute inset-0 opacity-30">
                  <div class="h-full w-full bg-[linear-gradient(rgba(255,255,255,0.06)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.06)_1px,transparent_1px)] bg-[size:32px_32px]">
                  </div>
                </div>

                <div class="absolute left-5 top-5 flex items-center gap-2 rounded-full bg-black/35 px-3 py-2 text-sm font-medium text-white backdrop-blur">
                  <span class="size-2 rounded-full bg-error"></span> LIVE
                </div>

                <div class="absolute right-5 top-5 rounded-full bg-success px-3 py-2 text-sm font-medium text-success-content">
                  {camera.status}
                </div>

                <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 to-transparent p-5">
                  <div class="text-sm text-white/60">Demo camera feed</div>

                  <div class="mt-1 text-2xl font-semibold text-white">
                    {camera.title}
                  </div>
                </div>
              </div>

              <div class="p-6">
                <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <h2 class="text-2xl font-semibold">{camera.subtitle}</h2>

                    <p class="mt-2 leading-7 text-base-content/65">
                      {camera.vehicle_hint}
                    </p>
                  </div>

                  <span class="badge badge-primary badge-lg">
                    {camera.title}
                  </span>
                </div>

                <div class="mt-6 rounded-2xl border border-white/10 bg-base-200/60 p-4 text-sm leading-6 text-base-content/70">
                  В MVP это демонстрационная карточка камеры. В реальном автосервисе сюда можно
                  подключить RTSP/HLS/WebRTC-поток с камеры конкретного бокса.
                </div>

                <div class="mt-6 flex flex-wrap gap-3">
                  <a href={camera.demo_url} target="_blank" rel="noopener" class="btn btn-primary">
                    Открыть демо-камеры
                  </a>

                  <a href="/my-bookings" class="btn btn-outline">
                    Проверить мою запись
                  </a>
                </div>
              </div>
            </article>
          <% end %>
        </section>
      </div>
    </main>
    """
  end
end
