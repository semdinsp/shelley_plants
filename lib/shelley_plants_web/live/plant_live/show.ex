defmodule ShelleyPlantsWeb.PlantLive.Show do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div class="flex items-center justify-between gap-4 mb-6">
          <.button navigate={~p"/plants"}>
            <.icon name="hero-arrow-left" /> Back to plants
          </.button>
          <.button
            :if={@current_scope && @current_scope.admin?}
            variant="primary"
            navigate={~p"/plants/#{@plant}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit plant
          </.button>
        </div>

        <article class="card bg-base-100 shadow-md overflow-hidden">
          <%!-- Photo --%>
          <figure class="relative h-64 sm:h-80 overflow-hidden bg-base-200">
            <%= if @plant.picture do %>
              <img
                src={@plant.picture}
                alt={@plant.common_name}
                class="w-full h-full object-cover"
              />
            <% else %>
              <div class="w-full h-full flex flex-col items-center justify-center text-base-content/30">
                <.icon name="hero-photo" class="size-16" />
                <span class="mt-2 text-sm">No photo yet</span>
              </div>
            <% end %>
            <%= if @plant.native_ontario do %>
              <span class="absolute top-3 right-3 badge badge-success badge-sm gap-1 shadow">
                <.icon name="hero-map-pin" class="size-3" /> Ontario Native
              </span>
            <% end %>
          </figure>

          <div class="card-body p-6 sm:p-8 gap-6">
            <%!-- Names --%>
            <div>
              <h1 class="text-2xl sm:text-3xl font-serif font-semibold text-base-content leading-tight">
                {@plant.common_name}
              </h1>
              <p class="text-base italic text-base-content/60 mt-1">{@plant.latin_name}</p>
            </div>

            <%!-- Badges --%>
            <div class="flex flex-wrap gap-2">
              <span :if={@plant.category} class="badge badge-outline">{@plant.category}</span>
              <span class="badge badge-outline">{capitalize(@plant.plant_type)}</span>
              <span :if={@plant.locally_native} class="badge badge-outline gap-1">
                <.icon name="hero-map-pin" class="size-3" /> Locally native
              </span>
              <span :if={@plant.deer_resistant} class="badge badge-outline gap-1">
                <.icon name="hero-shield-check" class="size-3" /> Deer resistant
              </span>
              <span :if={@plant.chelsea_chop} class="badge badge-outline gap-1">
                <.icon name="hero-scissors" class="size-3" /> Chelsea chop
              </span>
            </div>

            <%!-- Icon fact grid --%>
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-x-4 gap-y-5 border-y border-base-200 py-6">
              <.fact icon="hero-swatch" label="Flower colour" value={@plant.flower_color} />
              <.fact icon="hero-calendar" label="Bloom time" value={@plant.bloom_time} />
              <.fact icon="hero-arrows-up-down" label="Height" value={@plant.height} />
              <.fact icon="hero-sun" label="Light" value={@plant.light_requirements} />
              <.fact icon="hero-beaker" label="Moisture" value={@plant.moisture} />
              <.fact
                icon="hero-globe-americas"
                label="Native to Ontario"
                value={if @plant.native_ontario, do: "Yes", else: "Non-native"}
              />
            </div>

            <%!-- Ecological benefit --%>
            <div :if={@plant.ecological_benefit}>
              <h2 class="flex items-center gap-1.5 text-sm font-semibold text-base-content mb-2">
                <.icon name="hero-sparkles" class="size-4 text-success" /> Ecological benefit
              </h2>
              <p class="text-sm text-base-content/70 leading-relaxed">
                {@plant.ecological_benefit}
              </p>
            </div>

            <%!-- Notes --%>
            <div :if={@plant.notes}>
              <h2 class="text-sm font-semibold text-base-content mb-2">Notes</h2>
              <p class="text-sm text-base-content/70 leading-relaxed">{@plant.notes}</p>
            </div>
          </div>
        </article>
      </div>
    </Layouts.app>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true

  defp fact(assigns) do
    ~H"""
    <div class="flex items-start gap-2 min-w-0">
      <.icon name={@icon} class="size-5 shrink-0 mt-0.5 text-primary" />
      <div class="min-w-0">
        <p class="text-xs text-base-content/50">{@label}</p>
        <p class="text-sm text-base-content font-medium">{@value || "—"}</p>
      </div>
    </div>
    """
  end

  defp capitalize(nil), do: "—"
  defp capitalize(str), do: String.capitalize(str)

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Catalog.subscribe_plants()
    end

    {:ok,
     socket
     |> then(fn socket ->
       plant = Catalog.get_plant!(id)
       socket |> assign(:page_title, plant.common_name) |> assign(:plant, plant)
     end)}
  end

  @impl true
  def handle_info(
        {:updated, %ShelleyPlants.Catalog.Plant{id: id} = plant},
        %{assigns: %{plant: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :plant, plant)}
  end

  def handle_info(
        {:deleted, %ShelleyPlants.Catalog.Plant{id: id}},
        %{assigns: %{plant: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "This plant has been removed.")
     |> push_navigate(to: ~p"/plants")}
  end

  def handle_info({type, %ShelleyPlants.Catalog.Plant{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
