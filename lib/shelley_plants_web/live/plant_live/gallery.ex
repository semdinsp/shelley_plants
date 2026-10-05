defmodule ShelleyPlantsWeb.PlantLive.Gallery do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Catalog
  alias ShelleyPlantsWeb.PlantImages

  @categories ~w(Wildflower Grass Shrub Tree)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto">
        <div class="mb-8">
          <h1 class="text-3xl font-serif font-semibold text-base-content">Shop Plants</h1>
          <p class="mt-2 text-base-content/70">
            Explore Ontario's native plants — click any card to learn more.
          </p>
        </div>

        <%!-- Category filter buttons --%>
        <div class="flex flex-wrap gap-2 mb-8">
          <.link
            patch={~p"/plants/gallery"}
            class={"btn btn-sm #{if @category == nil, do: "btn-primary", else: "btn-ghost"}"}
          >
            All
          </.link>
          <.link
            :for={cat <- @categories}
            patch={~p"/plants/gallery?category=#{cat}"}
            class={"btn btn-sm #{if @category == cat, do: "btn-primary", else: "btn-ghost"}"}
          >
            {cat}
          </.link>
        </div>

        <%= if @plants == [] and @category do %>
          <.coming_soon category={@category} />
        <% else %>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            <.plant_card :for={plant <- @plants} plant={plant} />
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Shop Plants")
     |> assign(:categories, @categories)
     |> assign(:category, nil)
     |> assign(:plants, Catalog.list_plants())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    category = Map.get(params, "category")
    category = if category in @categories, do: category, else: nil

    {:noreply,
     socket
     |> assign(:category, category)
     |> assign(:plants, Catalog.list_plants_by_category(category))}
  end

  # ── Coming soon (category with no plants yet) ─────────────────────────────────

  attr :category, :string, required: true

  defp coming_soon(assigns) do
    assigns = assign(assigns, :label, String.downcase(assigns.category) <> "s")

    ~H"""
    <div
      id="coming-soon"
      class="rounded-box border border-dashed border-base-300 bg-base-200/50 px-6 py-16 text-center"
    >
      <.icon name="hero-sparkles" class="size-12 text-success" />
      <h2 class="mt-4 text-2xl font-serif font-semibold text-base-content">
        Native {@label} — coming soon
      </h2>
      <p class="mt-3 max-w-xl mx-auto text-base-content/70">
        We currently grow Ontario native wildflowers and grasses. Native {@label} are on the way — check back soon.
      </p>
      <div class="mt-8 flex flex-wrap justify-center gap-3">
        <.link patch={~p"/plants/gallery?category=Wildflower"} class="btn btn-primary btn-sm">
          Browse wildflowers
        </.link>
        <.link patch={~p"/plants/gallery?category=Grass"} class="btn btn-outline btn-sm">
          Browse grasses
        </.link>
      </div>
    </div>
    """
  end

  # ── Card component ────────────────────────────────────────────────────────────

  attr :plant, ShelleyPlants.Catalog.Plant, required: true

  defp plant_card(assigns) do
    ~H"""
    <article class="card bg-base-100 shadow-md hover:shadow-xl transition-shadow duration-300 overflow-hidden group">
      <%!-- Photo (links to the plant page, like "Learn more"; kept out of the
           tab order so keyboard users don't hit the same link twice) --%>
      <.link navigate={~p"/plants/#{@plant}"} tabindex="-1" class="block">
        <figure class="relative h-56 overflow-hidden bg-base-200">
          <%= if @plant.picture do %>
            <img
              src={PlantImages.thumb_url(@plant.picture)}
              alt={@plant.common_name}
              loading="lazy"
              decoding="async"
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
          <% else %>
            <%= if @plant.near_native do %>
              <span class="absolute top-3 right-3 badge badge-info badge-sm gap-1 shadow">
                <.icon name="hero-map-pin" class="size-3" /> Near Native
              </span>
            <% end %>
          <% end %>
        </figure>
      </.link>

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
          <.fact icon="hero-sun" label="Light" value={light_label(@plant)} />
          <.fact icon="hero-beaker" label="Moisture" value={moisture_label(@plant)} />
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

  # Cards use the short structured sun/moisture values (the free-text
  # descriptions are too long for the card and get truncated), falling back
  # to the free text for plants that don't have them set.
  defp light_label(%{sun_level: "full_sun"}), do: "Full sun"
  defp light_label(%{sun_level: "part_shade"}), do: "Part shade"
  defp light_label(%{sun_level: "full_shade"}), do: "Full shade"
  defp light_label(%{light_requirements: light}), do: light || "—"

  defp moisture_label(%{moisture_level: "wet"}), do: "Wet"
  defp moisture_label(%{moisture_level: "average"}), do: "Average"
  defp moisture_label(%{moisture_level: "dry"}), do: "Dry"
  defp moisture_label(%{moisture_level: "very_dry"}), do: "Very dry"
  defp moisture_label(%{moisture: moisture}), do: moisture || "—"
end
