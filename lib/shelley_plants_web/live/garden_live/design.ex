defmodule ShelleyPlantsWeb.GardenLive.Design do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.GardenDesign

  @height_structures [
    %{
      id: "low_uniform",
      label: "Low & uniform",
      desc: "Everything at a similar height — tidy and contained"
    },
    %{
      id: "layered",
      label: "Layered",
      desc: "Short in front, tall in back — classic border look"
    },
    %{
      id: "mixed",
      label: "Mixed / naturalistic",
      desc: "Varied heights throughout — relaxed meadow feel"
    },
    %{id: "focal", label: "Tall focal points", desc: "Statement plants anchoring the space"}
  ]

  @sun_options [
    %{id: "full_sun", label: "Full sun", desc: "6+ hours of direct sun", icon: "hero-sun"},
    %{id: "part_shade", label: "Part shade", desc: "3–6 hours of direct sun", icon: "hero-cloud"},
    %{
      id: "full_shade",
      label: "Full shade",
      desc: "Under 3 hours of direct sun",
      icon: "hero-moon"
    }
  ]

  @moisture_options [
    %{id: "dry", label: "Dry", desc: "Drains quickly, rarely stays wet"},
    %{id: "average", label: "Average", desc: "Typical garden soil moisture"},
    %{id: "moist", label: "Moist", desc: "Stays consistently damp"},
    %{id: "wet", label: "Wet", desc: "Poor drainage or low-lying"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Garden Planner")
     |> assign(:height_structures, @height_structures)
     |> assign(:sun_options, @sun_options)
     |> assign(:moisture_options, @moisture_options)
     |> assign(:form_data, %{
       "width" => "",
       "length" => "",
       "max_height" => "",
       "height_structure" => nil,
       "sun" => nil,
       "moisture" => nil
     })
     |> assign(:state, :form)
     |> assign(:loading, false)
     |> assign(:advanced_expanded, false)
     |> assign(:plants, [])
     |> assign(:alternates, %{})
     |> assign(:expanded_alternates, MapSet.new())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-12">
        <div class="mb-10">
          <p class="text-xs font-semibold uppercase tracking-[0.2em] text-primary mb-3">
            Plan your space
          </p>
          <h1 class="text-4xl font-bold font-serif tracking-tight text-base-content mb-4">
            Garden Planner
          </h1>
          <p class="text-lg text-base-content/60 leading-relaxed max-w-xl">
            Tell us about your outdoor space and we'll suggest native Ontario plants
            perfectly suited to it — by size, light, and structure.
          </p>
        </div>

        <%!-- Professional design callout --%>
        <div class="bg-accent/10 border border-accent/20 rounded-2xl p-5 mb-10 flex items-start gap-4">
          <.icon name="hero-light-bulb" class="size-5 text-accent shrink-0 mt-0.5" />
          <div class="text-sm text-base-content/70 leading-relaxed">
            <p class="font-semibold text-base-content mb-1">A note on garden design</p>
            <p>
              Creating a garden that truly thrives takes more than a plant list — it involves
              grading, soil preparation, drainage, and a trained eye for how plants
              grow together over time. This tool is a starting point, not a substitute for
              professional expertise.
            </p>
            <p class="mt-2">
              For full landscape design, I warmly recommend my colleague
              <a
                href="https://www.north44ld.com/"
                target="_blank"
                rel="noopener noreferrer"
                class="font-semibold text-primary underline underline-offset-2 hover:text-primary/80"
              >
                Ashley at North 44 Landscape Design
              </a>
              — a talented designer I collaborate with closely and trust completely.
            </p>
          </div>
        </div>

        <%= if @state == :form do %>
          <.garden_form
            form_data={@form_data}
            height_structures={@height_structures}
            sun_options={@sun_options}
            moisture_options={@moisture_options}
            advanced_expanded={@advanced_expanded}
            loading={@loading}
          />
        <% else %>
          <.results_section
            plants={@plants}
            alternates={@alternates}
            form_data={@form_data}
            expanded_alternates={@expanded_alternates}
          />
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
  attr :height_structures, :list, required: true
  attr :sun_options, :list, required: true
  attr :moisture_options, :list, required: true
  attr :advanced_expanded, :boolean, required: true
  attr :loading, :boolean, required: true

  defp garden_form(assigns) do
    ~H"""
    <form id="garden-planner-form" phx-submit="submit" phx-change="validate" class="space-y-10">
      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="1" title="Garden size" />
        <p class="text-sm text-base-content/50 mb-6">
          Enter the approximate dimensions of your planting area.
        </p>
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
            ≈ {Float.round(parse_float(@form_data["width"]) * parse_float(@form_data["length"]), 1)} m²
          </p>
        <% end %>
      </section>

      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="2" title="Sun exposure" />
        <p class="text-sm text-base-content/50 mb-6">How much direct sunlight does this spot get?</p>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <%= for sun <- @sun_options do %>
            <label class="cursor-pointer">
              <input
                type="radio"
                name="sun"
                value={sun.id}
                class="sr-only peer"
                checked={@form_data["sun"] == sun.id}
              />
              <div class="flex flex-col items-center gap-2 p-4 rounded-xl border-2 border-base-200 peer-checked:border-primary peer-checked:bg-primary/5 hover:border-primary/50 transition-colors text-center">
                <.icon name={sun.icon} class="size-7 text-base-content/40 peer-checked:text-primary" />
                <p class="text-sm font-semibold text-base-content">{sun.label}</p>
                <p class="text-xs text-base-content/50 leading-tight">{sun.desc}</p>
              </div>
            </label>
          <% end %>
        </div>
      </section>

      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="3" title="Moisture level" />
        <p class="text-sm text-base-content/50 mb-6">
          How much moisture does this spot typically hold?
        </p>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <%= for moisture <- @moisture_options do %>
            <label class="cursor-pointer">
              <input
                type="radio"
                name="moisture"
                value={moisture.id}
                class="sr-only peer"
                checked={@form_data["moisture"] == moisture.id}
              />
              <div class="flex flex-col items-center gap-1 p-4 rounded-xl border-2 border-base-200 peer-checked:border-primary peer-checked:bg-primary/5 hover:border-primary/50 transition-colors text-center">
                <p class="text-sm font-semibold text-base-content">{moisture.label}</p>
                <p class="text-xs text-base-content/50 leading-tight">{moisture.desc}</p>
              </div>
            </label>
          <% end %>
        </div>
      </section>

      <section class="bg-base-100 border border-base-200 rounded-2xl overflow-hidden shadow-sm">
        <button
          type="button"
          phx-click="toggle_advanced"
          class="w-full flex items-center justify-between gap-3 p-6 sm:p-8 text-left"
        >
          <span class="text-base font-semibold text-base-content">Advanced options</span>
          <.icon
            name={if @advanced_expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
            class="size-5 text-base-content/40 shrink-0"
          />
        </button>

        <div
          :if={@advanced_expanded}
          class="px-6 sm:px-8 pb-6 sm:pb-8 space-y-8 border-t border-base-200 pt-6"
        >
          <div>
            <p class="text-sm font-medium text-base-content mb-1.5">Maximum plant height</p>
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
                Think about fences, windowsills, or a neighbour's view. Leave blank for no constraint.
              </p>
            </div>
          </div>

          <div>
            <p class="text-sm font-medium text-base-content mb-1.5">Height structure</p>
            <p class="text-sm text-base-content/50 mb-4">
              How do you want the heights to work together?
            </p>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <%= for hs <- @height_structures do %>
                <label class="cursor-pointer">
                  <input
                    type="radio"
                    name="height_structure"
                    value={hs.id}
                    class="sr-only peer"
                    checked={@form_data["height_structure"] == hs.id}
                  />
                  <div class="flex items-start gap-3 p-4 rounded-xl border-2 border-base-200 peer-checked:border-primary peer-checked:bg-primary/5 hover:border-primary/50 transition-colors h-full">
                    <div>
                      <p class="text-sm font-semibold text-base-content">{hs.label}</p>
                      <p class="text-xs text-base-content/50 mt-0.5 leading-relaxed">{hs.desc}</p>
                    </div>
                  </div>
                </label>
              <% end %>
            </div>
          </div>
        </div>
      </section>

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
  attr :alternates, :map, required: true
  attr :form_data, :map, required: true
  attr :expanded_alternates, :any, required: true

  defp results_section(assigns) do
    ~H"""
    <div class="space-y-10">
      <%!-- Summary card --%>
      <div class="bg-success/10 border border-success/20 rounded-2xl p-6 flex items-start gap-4">
        <.icon name="hero-check-circle" class="size-6 text-success shrink-0 mt-0.5" />
        <div>
          <p class="font-semibold text-base-content">Your garden plan is ready!</p>
          <p class="text-sm text-base-content/60 mt-1 leading-relaxed">
            {summary_text(@form_data, @plants)}
          </p>
        </div>
      </div>

      <%!-- Weak moisture match note --%>
      <div
        :if={weak_moisture_match?(@form_data, @plants)}
        class="bg-warning/10 border border-warning/20 rounded-2xl p-5 flex items-start gap-4"
      >
        <.icon name="hero-exclamation-triangle" class="size-5 text-warning shrink-0 mt-0.5" />
        <p class="text-sm text-base-content/70 leading-relaxed">
          Few plants in the catalog are confirmed {human_moisture(@form_data["moisture"])
          |> String.downcase()}-tolerant for this light level, so some suggestions below are the
          closest available match rather than a confirmed fit for that moisture level.
        </p>
      </div>

      <%!-- Plant purchase list --%>
      <section>
        <div class="flex items-start justify-between gap-4">
          <div>
            <h2 class="text-lg font-semibold text-base-content mb-1">Plant List</h2>
            <p class="text-sm text-base-content/50 mb-4">
              Suggested plants for your space, with recommended quantities. Expand each plant to see alternatives.
            </p>
          </div>
          <a
            href={~p"/garden-planner/export?#{@form_data}"}
            class="btn btn-outline btn-sm gap-2 shrink-0"
          >
            <.icon name="hero-arrow-down-tray" class="size-4" /> Download CSV
          </a>
        </div>

        <%!-- Total summary row --%>
        <div class="flex items-center justify-between bg-base-200/60 rounded-xl px-4 py-3 mb-4 text-sm">
          <span class="text-base-content/60">{length(@plants)} species recommended</span>
          <span class="font-semibold text-base-content">
            {Enum.sum(Enum.map(@plants, & &1.quantity))} plants total
          </span>
        </div>

        <%!-- Fit legend — sorted best fit first --%>
        <div class="flex flex-wrap items-center gap-x-5 gap-y-1.5 text-xs text-base-content/50 mb-4">
          <span class="font-medium text-base-content/60">Sorted by best fit:</span>
          <span class="flex items-center gap-1.5">
            <span
              class="size-2.5 rounded-full shrink-0"
              style={"background-color: #{fit_color(:great)}"}
            ></span>
            Great fit
          </span>
          <span class="flex items-center gap-1.5">
            <span
              class="size-2.5 rounded-full shrink-0"
              style={"background-color: #{fit_color(:good)}"}
            ></span>
            Good fit
          </span>
          <span class="flex items-center gap-1.5">
            <span
              class="size-2.5 rounded-full shrink-0"
              style={"background-color: #{fit_color(:fallback)}"}
            ></span>
            Fallback match
          </span>
        </div>

        <div class="space-y-3">
          <%= for plant <- @plants do %>
            <% alts = Map.get(@alternates, plant.id, []) %>
            <% expanded = MapSet.member?(@expanded_alternates, plant.id) %>

            <div class="border border-base-200 rounded-2xl overflow-hidden bg-base-100">
              <%!-- Main plant row --%>
              <div class="flex flex-col sm:flex-row sm:items-center gap-3 p-4">
                <div class="flex items-center gap-3 min-w-0">
                  <%!-- Colour dot --%>
                  <span
                    class="size-3 rounded-full shrink-0 hidden sm:block"
                    style={"background-color: #{plant.color}"}
                  ></span>

                  <%!-- Photo thumbnail --%>
                  <div class="size-14 rounded-xl overflow-hidden bg-base-200 shrink-0">
                    <%= if plant.picture do %>
                      <img
                        src={plant.picture}
                        alt={plant.common_name}
                        class="w-full h-full object-cover"
                      />
                    <% else %>
                      <div class="w-full h-full flex items-center justify-center text-base-content/20">
                        <.icon name="hero-photo" class="size-6" />
                      </div>
                    <% end %>
                  </div>

                  <%!-- Plant info --%>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-start justify-between gap-2">
                      <div class="min-w-0">
                        <p class="font-semibold text-sm text-base-content leading-tight">
                          {plant.common_name}
                        </p>
                        <p class="text-xs italic text-base-content/50 truncate">
                          {plant.latin_name}
                        </p>
                      </div>
                      <div class="text-right shrink-0">
                        <p class="text-lg font-bold text-primary leading-none">×{plant.quantity}</p>
                        <p class="text-xs text-base-content/40 mt-0.5">plants</p>
                      </div>
                    </div>
                    <div class="flex flex-wrap gap-1.5 mt-2">
                      <%= if plant.height_min_cm && plant.height_max_cm do %>
                        <span class="badge badge-ghost badge-xs gap-1">
                          <.icon name="hero-arrows-up-down" class="size-2.5" />
                          {plant.height_min_cm}–{plant.height_max_cm} cm
                        </span>
                      <% end %>
                      <%= if plant.category do %>
                        <span class="badge badge-ghost badge-xs">{plant.category}</span>
                      <% end %>
                      <%= if plant.sun_level do %>
                        <span class="badge badge-ghost badge-xs">{human_sun(plant.sun_level)}</span>
                      <% end %>
                      <%= if plant.moisture_level do %>
                        <span class="badge badge-ghost badge-xs">
                          {human_moisture(plant.moisture_level)}
                        </span>
                      <% end %>
                    </div>
                  </div>
                </div>

                <%!-- View + Alternates toggle --%>
                <div class="flex items-center justify-end gap-2 shrink-0 sm:flex-col sm:items-end">
                  <.link navigate={~p"/plants/#{plant}"} class="btn btn-ghost btn-xs gap-1">
                    <.icon name="hero-eye" class="size-3" /> View
                  </.link>
                  <%= if alts != [] do %>
                    <button
                      phx-click="toggle_alternates"
                      phx-value-id={plant.id}
                      class="btn btn-ghost btn-xs gap-1 text-base-content/50"
                    >
                      <.icon
                        name={if expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
                        class="size-3"
                      />
                      {length(alts)} alt{if length(alts) > 1, do: "s"}
                    </button>
                  <% end %>
                </div>
              </div>

              <%!-- Alternates drawer --%>
              <%= if expanded && alts != [] do %>
                <div class="border-t border-base-200 bg-base-50 px-4 py-3">
                  <p class="text-xs font-semibold text-base-content/40 uppercase tracking-wider mb-3">
                    Alternative plants
                  </p>
                  <div class="space-y-2">
                    <%= for alt <- alts do %>
                      <div class="flex items-center gap-3 py-1">
                        <div class="size-10 rounded-lg overflow-hidden bg-base-200 shrink-0">
                          <%= if alt.picture do %>
                            <img
                              src={alt.picture}
                              alt={alt.common_name}
                              class="w-full h-full object-cover"
                            />
                          <% else %>
                            <div class="w-full h-full flex items-center justify-center text-base-content/20">
                              <.icon name="hero-photo" class="size-4" />
                            </div>
                          <% end %>
                        </div>
                        <div class="flex-1 min-w-0">
                          <p class="text-sm font-medium text-base-content leading-tight">
                            {alt.common_name}
                          </p>
                          <p class="text-xs italic text-base-content/40 truncate">{alt.latin_name}</p>
                        </div>
                        <.link navigate={~p"/plants/#{alt}"} class="btn btn-ghost btn-xs">
                          <.icon name="hero-eye" class="size-3" />
                        </.link>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </section>
    </div>
    """
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

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

  defp parse_float(_), do: 0.0

  defp human_sun("full_sun"), do: "Full sun"
  defp human_sun("part_shade"), do: "Part shade"
  defp human_sun("full_shade"), do: "Full shade"
  defp human_sun(_), do: ""

  defp human_moisture("dry"), do: "Dry"
  defp human_moisture("average"), do: "Average"
  defp human_moisture("moist"), do: "Moist"
  defp human_moisture("wet"), do: "Wet"
  defp human_moisture(_), do: ""

  defp fit_color(level), do: Map.fetch!(GardenDesign.fit_colors(), level)

  # True when a moisture level was requested but fewer than half of the
  # recommended plants actually carry that moisture_level — meaning most of
  # what's shown is the closest available fallback, not a confirmed match.
  defp weak_moisture_match?(_form_data, []), do: false

  defp weak_moisture_match?(form_data, plants) do
    case form_data["moisture"] do
      moisture when moisture in [nil, ""] ->
        false

      moisture ->
        matches = Enum.count(plants, &(&1.moisture_level == moisture))
        matches < length(plants) / 2
    end
  end

  defp summary_text(form_data, plants) do
    w = form_data["width"]
    l = form_data["length"]
    sun = human_sun(form_data["sun"])
    moisture = human_moisture(form_data["moisture"])
    structure = form_data["height_structure"]
    total = Enum.sum(Enum.map(plants, & &1.quantity))

    size_str = if w != "" and l != "", do: "#{w}m × #{l}m garden", else: "your garden"
    sun_str = if sun != "", do: " in #{String.downcase(sun)}", else: ""

    moisture_str =
      if moisture != "", do: ", #{String.downcase(moisture)} soil", else: ""

    struct_str =
      case structure do
        "layered" -> ", layered from front to back"
        "low_uniform" -> ", kept low and uniform"
        "focal" -> ", with tall focal points"
        "mixed" -> ", mixed naturalistic style"
        _ -> ""
      end

    "#{length(plants)} species recommended for your #{size_str}#{sun_str}#{moisture_str}#{struct_str}. " <>
      "#{total} plants in total."
  end

  # ── Event handlers ────────────────────────────────────────────────────────────

  @impl true
  def handle_event("validate", params, socket) do
    form_data =
      Map.merge(
        socket.assigns.form_data,
        Map.take(params, ["width", "length", "max_height", "height_structure", "sun", "moisture"])
      )

    {:noreply, assign(socket, :form_data, form_data)}
  end

  @impl true
  def handle_event("submit", params, socket) do
    form_data =
      Map.merge(
        socket.assigns.form_data,
        Map.take(params, ["width", "length", "max_height", "height_structure", "sun", "moisture"])
      )

    {plants, alternates} = GardenDesign.recommend(form_data)

    {:noreply,
     socket
     |> assign(:form_data, form_data)
     |> assign(:plants, plants)
     |> assign(:alternates, alternates)
     |> assign(:state, :results)}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket) do
    {:noreply, assign(socket, :advanced_expanded, !socket.assigns.advanced_expanded)}
  end

  @impl true
  def handle_event("toggle_alternates", %{"id" => id}, socket) do
    expanded = socket.assigns.expanded_alternates

    updated =
      if MapSet.member?(expanded, id),
        do: MapSet.delete(expanded, id),
        else: MapSet.put(expanded, id)

    {:noreply, assign(socket, :expanded_alternates, updated)}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:state, :form)
     |> assign(:plants, [])
     |> assign(:alternates, %{})
     |> assign(:expanded_alternates, MapSet.new())}
  end
end
