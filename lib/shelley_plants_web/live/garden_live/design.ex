defmodule ShelleyPlantsWeb.GardenLive.Design do
  use ShelleyPlantsWeb, :live_view

  # TODO: replace mock_plants with real plant-matching query based on size/shape/height/sun inputs
  @mock_plants [
    %{
      common_name: "Black-eyed Susan",
      latin_name: "Rudbeckia hirta",
      height: "60–90 cm",
      light: "Full sun",
      picture: "/images/plants/rudbeckia_hirta.jpg",
      category: "Wildflower"
    },
    %{
      common_name: "Wild Bergamot",
      latin_name: "Monarda fistulosa",
      height: "60–120 cm",
      light: "Full sun to part shade",
      picture: "/images/plants/monarda_fistulosa.jpg",
      category: "Wildflower"
    },
    %{
      common_name: "New England Aster",
      latin_name: "Symphyotrichum novae-angliae",
      height: "90–150 cm",
      light: "Full sun",
      picture: "/images/plants/symphyotrichum_novae_angliae.jpg",
      category: "Wildflower"
    },
    %{
      common_name: "Swamp Milkweed",
      latin_name: "Asclepias incarnata",
      height: "90–120 cm",
      light: "Full sun to part shade",
      picture: "/images/plants/asclepias_incarnata.jpg",
      category: "Wildflower"
    },
    %{
      common_name: "Big Bluestem",
      latin_name: "Andropogon gerardii",
      height: "120–180 cm",
      light: "Full sun",
      picture: "/images/plants/andropogon_gerardii.jpg",
      category: "Grass"
    },
    %{
      common_name: "Columbine",
      latin_name: "Aquilegia canadensis",
      height: "30–60 cm",
      light: "Part shade",
      picture: "/images/plants/aquilegia_canadensis.jpg",
      category: "Wildflower"
    }
  ]

  @shapes [
    %{id: "rectangular", label: "Rectangular", svg: """
      <rect x="4" y="10" width="40" height="28" rx="1" stroke="currentColor" stroke-width="2" fill="none"/>
    """},
    %{id: "square", label: "Square", svg: """
      <rect x="9" y="9" width="30" height="30" rx="1" stroke="currentColor" stroke-width="2" fill="none"/>
    """},
    %{id: "triangular", label: "Triangular", svg: """
      <polygon points="24,6 44,42 4,42" stroke="currentColor" stroke-width="2" fill="none"/>
    """},
    %{id: "circular", label: "Circular / Oval", svg: """
      <ellipse cx="24" cy="24" rx="20" ry="16" stroke="currentColor" stroke-width="2" fill="none"/>
    """},
    %{id: "irregular", label: "Irregular / L-shaped", svg: """
      <polyline points="4,8 30,8 30,22 44,22 44,44 4,44 4,8" stroke="currentColor" stroke-width="2" fill="none"/>
    """}
  ]

  @height_structures [
    %{id: "low_uniform", label: "Low & uniform", desc: "Everything at a similar height — tidy and contained"},
    %{id: "layered", label: "Layered", desc: "Short in front, tall in back — classic border look"},
    %{id: "mixed", label: "Mixed / naturalistic", desc: "Varied heights throughout — relaxed meadow feel"},
    %{id: "focal", label: "Tall focal points", desc: "Statement plants anchoring the space"}
  ]

  @sun_options [
    %{id: "full_sun", label: "Full sun", desc: "6+ hours of direct sun", icon: "hero-sun"},
    %{id: "part_shade", label: "Part shade", desc: "3–6 hours of direct sun", icon: "hero-cloud"},
    %{id: "full_shade", label: "Full shade", desc: "Under 3 hours of direct sun", icon: "hero-moon"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Design Your Garden")
     |> assign(:shapes, @shapes)
     |> assign(:height_structures, @height_structures)
     |> assign(:sun_options, @sun_options)
     |> assign(:form_data, %{
       "width" => "",
       "length" => "",
       "shape" => nil,
       "max_height" => "",
       "height_structure" => nil,
       "sun" => nil
     })
     |> assign(:state, :form)
     |> assign(:loading, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-12">

        <%!-- Page header --%>
        <div class="mb-10">
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-primary mb-3">
            Plan your space
          </p>
          <h1 class="text-4xl font-bold font-serif tracking-tight text-base-content mb-4">
            Design Your Garden
          </h1>
          <p class="text-lg text-base-content/60 leading-relaxed max-w-xl">
            Tell us about your outdoor space and we'll suggest native Ontario plants
            perfectly suited to it — by size, light, and structure.
          </p>
        </div>

        <%= if @state == :form do %>
          <.garden_form
            form_data={@form_data}
            shapes={@shapes}
            height_structures={@height_structures}
            sun_options={@sun_options}
            loading={@loading}
          />
        <% else %>
          <.results_section plants={@mock_plants} form_data={@form_data} />
          <div class="mt-8 pt-6 border-t border-base-200">
            <button phx-click="reset" class="btn btn-ghost gap-2">
              <.icon name="hero-arrow-left" class="size-4" /> Start over
            </button>
          </div>
        <% end %>

      </div>
    </Layouts.app>
    """
  end

  # ── Form component ────────────────────────────────────────────────────────────

  attr :form_data, :map, required: true
  attr :shapes, :list, required: true
  attr :height_structures, :list, required: true
  attr :sun_options, :list, required: true
  attr :loading, :boolean, required: true

  defp garden_form(assigns) do
    ~H"""
    <form phx-submit="submit" phx-change="validate" class="space-y-10">

      <%!-- Section 1: Garden size --%>
      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="1" title="Garden size" />
        <p class="text-sm text-base-content/50 mb-6">Enter the approximate dimensions of your planting area.</p>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-base-content mb-1.5">Width (m)</label>
            <input
              type="number"
              name="width"
              value={@form_data["width"]}
              min="0.5"
              max="100"
              step="0.5"
              placeholder="e.g. 3"
              class="input input-bordered w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-base-content mb-1.5">Length (m)</label>
            <input
              type="number"
              name="length"
              value={@form_data["length"]}
              min="0.5"
              max="100"
              step="0.5"
              placeholder="e.g. 5"
              class="input input-bordered w-full"
            />
          </div>
        </div>
        <%= if @form_data["width"] != "" && @form_data["length"] != "" do %>
          <p class="text-xs text-base-content/40 mt-3">
            ≈ <%= Float.round(parse_float(@form_data["width"]) * parse_float(@form_data["length"]), 1) %> m²
          </p>
        <% end %>
      </section>

      <%!-- Section 2: Shape --%>
      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="2" title="Garden shape" />
        <p class="text-sm text-base-content/50 mb-6">Choose the shape that best describes your space.</p>
        <div class="grid grid-cols-3 sm:grid-cols-5 gap-3">
          <%= for shape <- @shapes do %>
            <label class={"cursor-pointer group"}>
              <input type="radio" name="shape" value={shape.id} class="sr-only peer" checked={@form_data["shape"] == shape.id} />
              <div class="flex flex-col items-center gap-2 p-3 rounded-xl border-2 border-base-200 peer-checked:border-primary peer-checked:bg-primary/5 hover:border-primary/50 transition-colors">
                <svg viewBox="0 0 48 48" class="w-10 h-10 text-base-content/40 peer-checked:text-primary group-has-[:checked]:text-primary" xmlns="http://www.w3.org/2000/svg">
                  <%= Phoenix.HTML.raw(shape.svg) %>
                </svg>
                <span class="text-xs text-center text-base-content/60 leading-tight"><%= shape.label %></span>
              </div>
            </label>
          <% end %>
        </div>
      </section>

      <%!-- Section 3: Max height --%>
      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="3" title="Maximum plant height" />
        <div class="max-w-xs">
          <label class="block text-sm font-medium text-base-content mb-1.5">Max height (cm)</label>
          <input
            type="number"
            name="max_height"
            value={@form_data["max_height"]}
            min="10"
            max="500"
            step="10"
            placeholder="e.g. 120"
            class="input input-bordered w-full"
          />
          <p class="text-xs text-base-content/40 mt-2 leading-relaxed">
            Think about fences, windowsills, sightlines, or a neighbour's view. Leave blank if there's no constraint.
          </p>
        </div>
      </section>

      <%!-- Section 4: Height structure --%>
      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="4" title="Height structure" />
        <p class="text-sm text-base-content/50 mb-6">How do you want the heights to work together?</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <%= for hs <- @height_structures do %>
            <label class="cursor-pointer">
              <input type="radio" name="height_structure" value={hs.id} class="sr-only peer" checked={@form_data["height_structure"] == hs.id} />
              <div class="flex items-start gap-3 p-4 rounded-xl border-2 border-base-200 peer-checked:border-primary peer-checked:bg-primary/5 hover:border-primary/50 transition-colors h-full">
                <div class="mt-0.5 size-4 rounded-full border-2 border-base-300 peer-checked:border-primary flex items-center justify-center shrink-0 peer-checked:bg-primary">
                </div>
                <div>
                  <p class="text-sm font-semibold text-base-content"><%= hs.label %></p>
                  <p class="text-xs text-base-content/50 mt-0.5 leading-relaxed"><%= hs.desc %></p>
                </div>
              </div>
            </label>
          <% end %>
        </div>
      </section>

      <%!-- Section 5: Sun exposure (suggested addition — see note below) --%>
      <%!-- NOTE: sun exposure is already on individual plant records (light_requirements field).
           Adding it here lets us filter recommendations. If you prefer to surface this
           field elsewhere (e.g. on the plant filter bar), you can remove this section
           and this input will simply be ignored by the matching logic. --%>
      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="5" title="Sun exposure" />
        <p class="text-sm text-base-content/50 mb-6">How much direct sunlight does this spot get?</p>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <%= for sun <- @sun_options do %>
            <label class="cursor-pointer">
              <input type="radio" name="sun" value={sun.id} class="sr-only peer" checked={@form_data["sun"] == sun.id} />
              <div class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 border-base-200 peer-checked:border-primary peer-checked:bg-primary/5 hover:border-primary/50 transition-colors text-center">
                <.icon name={sun.icon} class="size-7 text-base-content/40 peer-checked:text-primary" />
                <p class="text-sm font-semibold text-base-content"><%= sun.label %></p>
                <p class="text-xs text-base-content/50 leading-tight"><%= sun.desc %></p>
              </div>
            </label>
          <% end %>
        </div>
      </section>

      <%!-- Submit --%>
      <div class="flex justify-end">
        <button
          type="submit"
          class="btn btn-primary btn-lg gap-2 w-full sm:w-auto"
          disabled={@loading}
        >
          <%= if @loading do %>
            <span class="loading loading-spinner loading-sm"></span> Finding plants…
          <% else %>
            <.icon name="hero-sparkles" class="size-5" /> Generate My Garden Plan
          <% end %>
        </button>
      </div>

    </form>
    """
  end

  # ── Results component ─────────────────────────────────────────────────────────

  attr :plants, :list, required: true
  attr :form_data, :map, required: true

  defp results_section(assigns) do
    ~H"""
    <div>
      <%!-- Results header --%>
      <div class="bg-success/10 border border-success/20 rounded-2xl p-6 mb-8 flex items-start gap-4">
        <.icon name="hero-check-circle" class="size-6 text-success shrink-0 mt-0.5" />
        <div>
          <p class="font-semibold text-base-content">Your garden plan is ready!</p>
          <p class="text-sm text-base-content/60 mt-1">
            Based on your space, here are native plants suited to your garden.
          </p>
          <%!-- TODO: replace with dynamic summary once real matching is in place --%>
          <p class="text-xs text-warning mt-2 font-medium">
            ⚠ Sample results — full plant-matching logic coming soon
          </p>
        </div>
      </div>

      <%!-- TODO: replace @plants with real recommendations from Catalog.recommend_plants/1 --%>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        <%= for plant <- @plants do %>
          <article class="card bg-base-100 shadow-md hover:shadow-xl transition-shadow duration-300 overflow-hidden group border border-base-200">
            <figure class="relative h-48 overflow-hidden bg-base-200">
              <%= if plant.picture do %>
                <img
                  src={plant.picture}
                  alt={plant.common_name}
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
              <% else %>
                <div class="w-full h-full flex flex-col items-center justify-center text-base-content/30">
                  <.icon name="hero-photo" class="size-12" />
                </div>
              <% end %>
              <span class="absolute top-2 right-2 badge badge-ghost badge-sm bg-base-100/80 backdrop-blur-sm">
                <%= plant.category %>
              </span>
            </figure>
            <div class="card-body p-4 gap-2">
              <h3 class="font-semibold text-base leading-snug"><%= plant.common_name %></h3>
              <p class="text-xs italic text-base-content/50"><%= plant.latin_name %></p>
              <div class="flex flex-wrap gap-2 mt-1">
                <span class="badge badge-ghost badge-sm gap-1">
                  <.icon name="hero-arrows-up-down" class="size-3" /> <%= plant.height %>
                </span>
                <span class="badge badge-ghost badge-sm gap-1">
                  <.icon name="hero-sun" class="size-3" /> <%= plant.light %>
                </span>
              </div>
            </div>
          </article>
        <% end %>
      </div>
    </div>
    """
  end

  # ── Section heading helper ────────────────────────────────────────────────────

  attr :number, :string, required: true
  attr :title, :string, required: true

  defp section_heading(assigns) do
    ~H"""
    <div class="flex items-center gap-3 mb-5">
      <span class="flex size-7 items-center justify-center rounded-full bg-primary text-primary-content text-xs font-bold shrink-0">
        {@number}
      </span>
      <h2 class="text-base font-semibold text-base-content">{@title}</h2>
    </div>
    """
  end

  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error -> 0.0
    end
  end

  # ── Event handlers ────────────────────────────────────────────────────────────

  @impl true
  def handle_event("validate", params, socket) do
    form_data = Map.merge(socket.assigns.form_data, Map.take(params, ["width", "length", "shape", "max_height", "height_structure", "sun"]))
    {:noreply, assign(socket, :form_data, form_data)}
  end

  @impl true
  def handle_event("submit", params, socket) do
    form_data = Map.merge(socket.assigns.form_data, Map.take(params, ["width", "length", "shape", "max_height", "height_structure", "sun"]))

    socket =
      socket
      |> assign(:form_data, form_data)
      |> assign(:loading, true)

    # TODO: replace with real async plant-matching task once backend logic is built
    Process.send_after(self(), :finish_loading, 1500)

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:state, :form)
     |> assign(:loading, false)
     |> assign(:mock_plants, @mock_plants)}
  end

  @impl true
  def handle_info(:finish_loading, socket) do
    # TODO: replace @mock_plants with real recommendations from Catalog.recommend_plants/1
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:state, :results)
     |> assign(:mock_plants, @mock_plants)}
  end
end
