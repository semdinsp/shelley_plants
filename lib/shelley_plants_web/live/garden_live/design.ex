defmodule ShelleyPlantsWeb.GardenLive.Design do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.GardenDesign

  @shapes [
    %{
      id: "rectangular",
      label: "Rectangular",
      svg: """
        <rect x="4" y="10" width="40" height="28" rx="1" stroke="currentColor" stroke-width="2" fill="none"/>
      """
    },
    %{
      id: "square",
      label: "Square",
      svg: """
        <rect x="9" y="9" width="30" height="30" rx="1" stroke="currentColor" stroke-width="2" fill="none"/>
      """
    },
    %{
      id: "triangular",
      label: "Triangular",
      svg: """
        <polygon points="24,6 44,42 4,42" stroke="currentColor" stroke-width="2" fill="none"/>
      """
    },
    %{
      id: "circular",
      label: "Circular / Oval",
      svg: """
        <ellipse cx="24" cy="24" rx="20" ry="16" stroke="currentColor" stroke-width="2" fill="none"/>
      """
    },
    %{
      id: "irregular",
      label: "Irregular / L-shaped",
      svg: """
        <polyline points="4,8 30,8 30,22 44,22 44,44 4,44 4,8" stroke="currentColor" stroke-width="2" fill="none"/>
      """
    }
  ]

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
     |> assign(:loading, false)
     |> assign(:plants, [])
     |> assign(:alternates, %{})
     |> assign(:diagram, nil)
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
            Design Your Garden
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
            shapes={@shapes}
            height_structures={@height_structures}
            sun_options={@sun_options}
            loading={@loading}
          />
        <% else %>
          <.results_section
            plants={@plants}
            alternates={@alternates}
            diagram={@diagram}
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
  attr :shapes, :list, required: true
  attr :height_structures, :list, required: true
  attr :sun_options, :list, required: true
  attr :loading, :boolean, required: true

  defp garden_form(assigns) do
    ~H"""
    <form phx-submit="submit" phx-change="validate" class="space-y-10">
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
        <.section_heading number="2" title="Garden shape" />
        <p class="text-sm text-base-content/50 mb-6">
          Choose the shape that best describes your space.
        </p>
        <div class="grid grid-cols-3 sm:grid-cols-5 gap-3">
          <%= for shape <- @shapes do %>
            <label class="cursor-pointer group">
              <input
                type="radio"
                name="shape"
                value={shape.id}
                class="sr-only peer"
                checked={@form_data["shape"] == shape.id}
              />
              <div class="flex flex-col items-center gap-2 p-3 rounded-xl border-2 border-base-200 peer-checked:border-primary peer-checked:bg-primary/5 hover:border-primary/50 transition-colors">
                <svg
                  viewBox="0 0 48 48"
                  class="w-10 h-10 text-base-content/40 group-has-[:checked]:text-primary"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  {Phoenix.HTML.raw(shape.svg)}
                </svg>
                <span class="text-xs text-center text-base-content/60 leading-tight">
                  {shape.label}
                </span>
              </div>
            </label>
          <% end %>
        </div>
      </section>

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
            Think about fences, windowsills, or a neighbour's view. Leave blank for no constraint.
          </p>
        </div>
      </section>

      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="4" title="Height structure" />
        <p class="text-sm text-base-content/50 mb-6">How do you want the heights to work together?</p>
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
                <div class="mt-0.5 size-4 rounded-full border-2 border-base-300 peer-checked:border-primary peer-checked:bg-primary shrink-0">
                </div>
                <div>
                  <p class="text-sm font-semibold text-base-content">{hs.label}</p>
                  <p class="text-xs text-base-content/50 mt-0.5 leading-relaxed">{hs.desc}</p>
                </div>
              </div>
            </label>
          <% end %>
        </div>
      </section>

      <section class="bg-base-100 border border-base-200 rounded-2xl p-6 sm:p-8 shadow-sm">
        <.section_heading number="5" title="Sun exposure" />
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
  attr :diagram, :any, required: true
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

      <%!-- Plant purchase list --%>
      <section>
        <h2 class="text-lg font-semibold text-base-content mb-1">Plant List</h2>
        <p class="text-sm text-base-content/50 mb-4">
          Suggested plants for your space, with recommended quantities. Expand each plant to see alternatives.
        </p>

        <%!-- Total summary row --%>
        <div class="flex items-center justify-between bg-base-200/60 rounded-xl px-4 py-3 mb-4 text-sm">
          <span class="text-base-content/60">{length(@plants)} species recommended</span>
          <span class="font-semibold text-base-content">
            {Enum.sum(Enum.map(@plants, & &1.quantity))} plants total
          </span>
        </div>

        <div class="space-y-3">
          <%= for plant <- @plants do %>
            <% alts = Map.get(@alternates, plant.id, []) %>
            <% expanded = MapSet.member?(@expanded_alternates, plant.id) %>

            <div class="border border-base-200 rounded-2xl overflow-hidden bg-base-100">
              <%!-- Main plant row --%>
              <div class="flex items-center gap-3 p-4">
                <%!-- Colour dot --%>
                <span class="size-3 rounded-full shrink-0" style={"background-color: #{plant.color}"}>
                </span>

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
                      <p class="font-semibold text-sm text-base-content leading-tight truncate">
                        {plant.common_name}
                      </p>
                      <p class="text-xs italic text-base-content/50 truncate">{plant.latin_name}</p>
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
                  </div>
                </div>

                <%!-- View + Alternates toggle --%>
                <div class="flex flex-col items-end gap-2 shrink-0">
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

      <%!-- Planting diagram — after the plant list --%>
      <%= if @diagram do %>
        <section>
          <h2 class="text-lg font-semibold text-base-content mb-1">Planting Diagram</h2>
          <p class="text-sm text-base-content/50 mb-4">
            A bird's-eye view of how your plants might be arranged. Each circle represents one plant, sized by its spread.
          </p>

          <div class="bg-base-200/60 rounded-2xl p-4 overflow-x-auto">
            <% {cw, ch, circles} = @diagram %>
            <svg
              viewBox={"0 0 #{cw} #{ch}"}
              width={min(cw, 520)}
              height={round(ch * min(cw, 520) / max(cw, 1))}
              class="block mx-auto"
              style="max-width: 100%"
            >
              <rect
                x="1"
                y="1"
                width={cw - 2}
                height={ch - 2}
                rx="6"
                fill="#e8f5ee"
                fill-opacity="0.3"
                stroke="#2d6a4f"
                stroke-width="2"
                stroke-dasharray="6,3"
              />
              <%= for circle <- circles do %>
                <g>
                  <circle
                    cx={circle.x}
                    cy={circle.y}
                    r={circle.r}
                    fill={circle.color}
                    fill-opacity="0.85"
                    stroke="white"
                    stroke-width="1.5"
                  />
                  <%= if circle.r >= 14 do %>
                    <text
                      x={circle.x}
                      y={circle.y + 4}
                      text-anchor="middle"
                      font-size="8"
                      fill="white"
                      font-family="sans-serif"
                      font-weight="600"
                    >
                      {String.split(circle.label, " ") |> List.first()}
                    </text>
                  <% end %>
                </g>
              <% end %>
            </svg>
          </div>

          <div class="mt-4 flex flex-wrap gap-x-5 gap-y-2">
            <%= for plant <- @plants do %>
              <div class="flex items-center gap-2 text-sm">
                <span class="size-3 rounded-full shrink-0" style={"background-color: #{plant.color}"}>
                </span>
                <span class="text-base-content/70">{plant.common_name}</span>
                <span class="text-base-content/40 text-xs">×{plant.quantity}</span>
              </div>
            <% end %>
          </div>
        </section>
      <% end %>
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

  defp summary_text(form_data, plants) do
    w = form_data["width"]
    l = form_data["length"]
    sun = human_sun(form_data["sun"])
    structure = form_data["height_structure"]
    total = Enum.sum(Enum.map(plants, & &1.quantity))

    size_str = if w != "" and l != "", do: "#{w}m × #{l}m garden", else: "your garden"
    sun_str = if sun != "", do: " in #{String.downcase(sun)}", else: ""

    struct_str =
      case structure do
        "layered" -> ", layered from front to back"
        "low_uniform" -> ", kept low and uniform"
        "focal" -> ", with tall focal points"
        "mixed" -> ", mixed naturalistic style"
        _ -> ""
      end

    "#{length(plants)} species recommended for your #{size_str}#{sun_str}#{struct_str}. " <>
      "#{total} plants in total."
  end

  # ── Event handlers ────────────────────────────────────────────────────────────

  @impl true
  def handle_event("validate", params, socket) do
    form_data =
      Map.merge(
        socket.assigns.form_data,
        Map.take(params, ["width", "length", "shape", "max_height", "height_structure", "sun"])
      )

    {:noreply, assign(socket, :form_data, form_data)}
  end

  @impl true
  def handle_event("submit", params, socket) do
    form_data =
      Map.merge(
        socket.assigns.form_data,
        Map.take(params, ["width", "length", "shape", "max_height", "height_structure", "sun"])
      )

    {plants, alternates} = GardenDesign.recommend(form_data)
    diagram = GardenDesign.diagram_data(plants, form_data)

    {:noreply,
     socket
     |> assign(:form_data, form_data)
     |> assign(:plants, plants)
     |> assign(:alternates, alternates)
     |> assign(:diagram, diagram)
     |> assign(:state, :results)}
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
     |> assign(:diagram, nil)
     |> assign(:expanded_alternates, MapSet.new())}
  end
end
