defmodule ShelleyPlantsWeb.PlantLive.Gallery do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
        <div class="mb-8">
          <h1 class="text-3xl font-serif font-semibold text-base-content">Visual Tour</h1>
          <p class="mt-2 text-base-content/70">
            Explore Ontario's native plants — click any card to learn more.
          </p>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          <.plant_card :for={plant <- @plants} plant={plant} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    plants = Catalog.list_plants()

    {:ok,
     socket
     |> assign(:page_title, "Visual Tour")
     |> assign(:plants, plants)}
  end

  # ── Card component ────────────────────────────────────────────────────────────

  attr :plant, ShelleyPlants.Catalog.Plant, required: true

  defp plant_card(assigns) do
    ~H"""
    <article class="card bg-base-100 shadow-md hover:shadow-xl transition-shadow duration-300 overflow-hidden group">
      <%!-- Photo --%>
      <figure class="relative h-56 overflow-hidden bg-base-200">
        <%= if @plant.picture do %>
          <img
            src={@plant.picture}
            alt={@plant.common_name}
            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
          />
        <% else %>
          <div class="w-full h-full flex flex-col items-center justify-center text-base-content/30">
            <.icon name="hero-photo" class="size-16" />
            <span class="mt-2 text-sm">No photo yet</span>
          </div>
        <% end %>
        <%!-- Native badge --%>
        <%= if @plant.native_ontario do %>
          <span class="absolute top-3 right-3 badge badge-success badge-sm gap-1 shadow">
            <.icon name="hero-map-pin" class="size-3" /> Ontario Native
          </span>
        <% end %>
      </figure>

      <div class="card-body p-4 gap-3">
        <%!-- Names --%>
        <div>
          <h2 class="card-title text-base font-semibold leading-snug">
            {@plant.common_name}
          </h2>
          <p class="text-sm italic text-base-content/60">{@plant.latin_name}</p>
        </div>

        <%!-- Icon fact strip --%>
        <div class="grid grid-cols-2 gap-x-3 gap-y-2 text-sm text-base-content/80">
          <.fact icon="hero-swatch" label="Colour" value={@plant.flower_color} />
          <.fact icon="hero-tag" label="Type" value={capitalize(@plant.plant_type)} />
          <.fact icon="hero-arrows-up-down" label="Height" value={@plant.height} />
          <.fact icon="hero-sun" label="Light" value={short_light(@plant.light_requirements)} />
          <.fact icon="hero-beaker" label="Moisture" value={@plant.moisture} />
          <.fact
            icon="hero-shield-check"
            label="Deer resistant"
            value={if @plant.deer_resistant, do: "Yes", else: "No"}
          />
        </div>

        <%!-- Ecological benefit teaser --%>
        <%= if @plant.ecological_benefit do %>
          <p class="text-xs text-base-content/60 line-clamp-2 border-t border-base-200 pt-2">
            <.icon name="hero-sparkles" class="size-3 inline mr-1 text-success" />
            {@plant.ecological_benefit}
          </p>
        <% end %>

        <%!-- Action --%>
        <div class="card-actions justify-end mt-1">
          <.link navigate={~p"/plants/#{@plant}"} class="btn btn-primary btn-sm">
            Learn more <.icon name="hero-arrow-right" class="size-4" />
          </.link>
        </div>
      </div>
    </article>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true

  defp fact(assigns) do
    ~H"""
    <div class="flex items-start gap-1.5 min-w-0">
      <.icon name={@icon} class="size-4 shrink-0 mt-0.5 text-primary" />
      <span class="truncate" title={@value}>{@value}</span>
    </div>
    """
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp capitalize(nil), do: "—"
  defp capitalize(str), do: String.capitalize(str)

  defp short_light(nil), do: "—"

  defp short_light(light) do
    light
    |> String.replace("to part shade", "/ part shade")
    |> String.replace("to full shade", "/ full shade")
    |> String.replace("Full sun", "Full sun")
    |> String.replace("Part shade", "Part shade")
  end
end
