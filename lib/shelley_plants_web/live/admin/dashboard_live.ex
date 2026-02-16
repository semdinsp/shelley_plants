defmodule ShelleyPlantsWeb.Admin.DashboardLive do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Admin Dashboard
        <:subtitle>Manage the native plants catalogue.</:subtitle>
      </.header>

      <%!-- Stats row --%>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-6">
        <div class="stat bg-base-200 rounded-2xl">
          <div class="stat-title">Total plants</div>
          <div class="stat-value text-primary">{@plant_count}</div>
        </div>
        <div class="stat bg-base-200 rounded-2xl">
          <div class="stat-title">With images</div>
          <div class="stat-value text-accent">{@with_picture_count}</div>
        </div>
        <div class="stat bg-base-200 rounded-2xl">
          <div class="stat-title">Missing images</div>
          <div class="stat-value text-warning">{@without_picture_count}</div>
        </div>
      </div>

      <%!-- Actions --%>
      <section class="mt-8 space-y-4">
        <h2 class="text-lg font-semibold">Plant Management</h2>

        <div class="flex flex-col sm:flex-row flex-wrap gap-3">
          <.link navigate={~p"/plants"} class="btn btn-primary gap-2">
            <.icon name="hero-list-bullet" /> Browse &amp; Edit Plants
          </.link>
          <.link navigate={~p"/plants/new"} class="btn btn-secondary gap-2">
            <.icon name="hero-plus" /> Add New Plant
          </.link>
          <a href={~p"/admin/plants/export"} class="btn btn-outline gap-2">
            <.icon name="hero-arrow-down-tray" /> Export JSON
          </a>
        </div>

        <div class="alert mt-4">
          <.icon name="hero-information-circle" class="size-5 shrink-0" />
          <div>
            <p class="font-semibold">Plant image files</p>
            <p class="text-sm">
              Store plant images in <code>priv/static/images/plants/</code>.
              Reference them in the <strong>Picture</strong>
              field as <code>/images/plants/filename.jpg</code>.
              These paths are included in the JSON export and are compatible
              with <code>mix plants.import</code>.
            </p>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    plants = Catalog.list_plants()
    with_picture = Enum.count(plants, & &1.picture)

    {:ok,
     assign(socket,
       plant_count: length(plants),
       with_picture_count: with_picture,
       without_picture_count: length(plants) - with_picture
     )}
  end
end
