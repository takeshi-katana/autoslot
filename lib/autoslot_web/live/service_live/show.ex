defmodule AutoslotWeb.ServiceLive.Show do
  use AutoslotWeb, :live_view

  alias Autoslot.Services

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-base-200 px-6 py-10">
      <div class="mx-auto max-w-5xl">
        <div class="mb-8 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <a href="/services" class="text-sm text-primary hover:underline">
              ← К каталогу услуг
            </a>
            
            <h1 class="mt-4 text-4xl font-bold text-base-content">
              {@service.name}
            </h1>
            
            <p class="mt-3 max-w-2xl text-base-content/70">
              Карточка услуги из каталога автосервиса. Эти данные используются на клиентской
              странице онлайн-записи и при расчете доступных слотов.
            </p>
          </div>
          
          <div class="flex gap-3">
            <a href="/services" class="btn btn-outline">Все услуги</a>
            <a href={~p"/services/#{@service}/edit?return_to=show"} class="btn btn-primary">
              Редактировать
            </a>
          </div>
        </div>
        
        <section class="grid gap-6 lg:grid-cols-[1fr_320px]">
          <article class="rounded-2xl bg-base-100 p-6 shadow">
            <div class="flex flex-wrap gap-2">
              <span class="badge badge-primary badge-lg">
                {@service.duration_minutes} мин.
              </span>
              
              <span class="badge badge-outline badge-lg">
                {@service.price} ₽
              </span>
            </div>
            
            <h2 class="mt-6 text-2xl font-semibold">Описание</h2>
            
            <p class="mt-3 text-lg leading-8 text-base-content/70">
              {@service.description}
            </p>
          </article>
          
          <aside class="rounded-2xl bg-base-100 p-6 shadow">
            <h2 class="text-xl font-semibold">Параметры услуги</h2>
            
            <div class="mt-5 grid gap-4">
              <div class="rounded-xl border border-base-300 p-4">
                <div class="text-sm text-base-content/60">Название</div>
                
                <div class="mt-1 font-semibold">{@service.name}</div>
              </div>
              
              <div class="rounded-xl border border-base-300 p-4">
                <div class="text-sm text-base-content/60">Длительность</div>
                
                <div class="mt-1 font-semibold">{@service.duration_minutes} мин.</div>
              </div>
              
              <div class="rounded-xl border border-base-300 p-4">
                <div class="text-sm text-base-content/60">Цена</div>
                
                <div class="mt-1 font-semibold">{@service.price} ₽</div>
              </div>
            </div>
          </aside>
        </section>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    service = Services.get_service!(id)

    {:ok,
     socket
     |> assign(:page_title, "Услуга")
     |> assign(:service, service)}
  end
end
