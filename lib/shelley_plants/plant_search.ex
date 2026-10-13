defmodule ShelleyPlants.PlantSearch do
  @moduledoc """
  Read-only search over the public plant catalogue, for the public MCP
  endpoint (`ShelleyPlants.MCP.Public`).

  Everything here is read-only and returns only what the public plant pages
  already show (see `public_json/1`); it never touches users, newsletter
  subscribers, contact messages or anything else non-public. The catalogue is
  small, so filtering happens in memory.

  Not supported, because the catalogue has no such data: soil type, price,
  pot size and stock/availability.
  """

  alias ShelleyPlants.{Catalog, GardenDesign}
  alias ShelleyPlants.Catalog.Plant

  @max_results 25

  @categories ~w(Wildflower Grass Shrub Tree)
  @light_levels ~w(full_sun part_shade full_shade)
  @moisture_levels ~w(wet average dry very_dry)
  @seasons ~w(spring summer fall)

  # Wildlife goal -> words to look for in the ecological benefit and notes.
  @wildlife %{
    "pollinators" => ~w(pollinat bee bumblebee butterfl moth hoverfl wasp),
    "bees" => ~w(bee bumblebee),
    "butterflies" => ~w(butterfl monarch),
    "moths" => ~w(moth),
    "hummingbirds" => ~w(hummingbird),
    "birds" => ~w(bird songbird goldfinch finch),
    "host_plant" => ~w(host larva caterpillar)
  }

  @colours ~w(white cream yellow gold orange red pink mauve purple lavender violet blue green bronze brown)

  def max_results, do: @max_results

  # ── Search ──────────────────────────────────────────────────────────────────

  @doc """
  Searches the catalogue. Filters (all optional, string keys or atoms):

    * `query` — text in the common or Latin name
    * `category` — Wildflower, Grass, Shrub or Tree
    * `light` — full_sun, part_shade or full_shade
    * `moisture` — wet, average, dry or very_dry
    * `min_height_cm` / `max_height_cm` — the plant's mature height reaches
      at least / stays at most this many cm
    * `bloom_season` — spring, summer or fall
    * `flower_color` — text in the flower colour, e.g. "yellow"
    * `deer_resistant` — true/false
    * `wildlife` — pollinators, bees, butterflies, moths, hummingbirds, birds
      or host_plant
    * `ontario_native` — true for plants native to Ontario only
    * `limit` — at most #{@max_results}

  Returns `{:ok, %{total: n, plants: [...]}}` with at most `limit` plants, or
  `{:error, message}` for an invalid filter value.
  """
  def search(filters) do
    filters = normalize(filters)

    with :ok <- validate(filters) do
      matches = Enum.filter(Catalog.list_plants(), &matches?(&1, filters))
      limit = filters |> Map.get("limit", @max_results) |> min(@max_results) |> max(1)

      {:ok,
       %{total: length(matches), plants: matches |> Enum.take(limit) |> Enum.map(&summary_json/1)}}
    end
  end

  defp matches?(plant, filters) do
    Enum.all?(filters, fn
      {"query", q} -> contains?(plant.common_name, q) or contains?(plant.latin_name, q)
      {"category", c} -> plant.category == c
      {"light", l} -> plant.sun_level == l
      {"moisture", m} -> plant.moisture_level == m
      {"min_height_cm", h} -> is_integer(plant.height_max_cm) and plant.height_max_cm >= h
      {"max_height_cm", h} -> is_integer(plant.height_max_cm) and plant.height_max_cm <= h
      {"bloom_season", s} -> s in bloom_seasons(plant.bloom_time)
      {"flower_color", c} -> contains?(plant.flower_color, c)
      {"deer_resistant", d} -> plant.deer_resistant == d
      {"wildlife", w} -> supports_wildlife?(plant, w)
      {"ontario_native", true} -> plant.native_ontario
      {"ontario_native", false} -> true
      {"limit", _} -> true
    end)
  end

  defp supports_wildlife?(plant, goal) do
    text = String.downcase("#{plant.ecological_benefit} #{plant.notes}")
    Enum.any?(@wildlife[goal], &String.contains?(text, &1))
  end

  defp contains?(nil, _), do: false
  defp contains?(text, term), do: String.contains?(String.downcase(text), String.downcase(term))

  @doc """
  Seasons a free-text bloom time covers, e.g. "Late spring through early
  fall" -> ["spring", "summer", "fall"].
  """
  def bloom_seasons(nil), do: []

  def bloom_seasons(text) do
    found =
      ~r/spring|summer|fall|autumn/
      |> Regex.scan(String.downcase(text))
      |> Enum.map(fn
        ["autumn"] -> "fall"
        [season] -> season
      end)
      |> Enum.map(&Enum.find_index(@seasons, fn s -> s == &1 end))

    case found do
      [] -> []
      indexes -> Enum.slice(@seasons, Enum.min(indexes)..Enum.max(indexes))
    end
  end

  # ── Single plant ────────────────────────────────────────────────────────────

  @doc """
  Finds a plant by slug ("aquilegia-canadensis") or Latin name ("Aquilegia
  canadensis", case-insensitive). Returns `{:ok, full_json}` or
  `{:error, :not_found}`.
  """
  def get(slug_or_latin) when is_binary(slug_or_latin) do
    term = String.trim(slug_or_latin)

    plant =
      Catalog.get_plant_by_slug(term) ||
        Catalog.get_plant_by_slug(Plant.slugify(term))

    if plant, do: {:ok, public_json(plant)}, else: {:error, :not_found}
  end

  # ── Recommendations ─────────────────────────────────────────────────────────

  @doc """
  Recommends plants for site conditions using the garden planner's matching
  (`ShelleyPlants.GardenDesign.recommend/1`): `light` (required), `moisture`,
  `max_height_cm` and `wildlife`. Each plant gets a `fit` of great, good or
  fallback.
  """
  def recommend(conditions) do
    conditions = normalize(conditions)

    with :ok <- validate(conditions),
         {:ok, light} <- fetch_required(conditions, "light") do
      {plants, _alternates} =
        GardenDesign.recommend(%{
          "sun" => light,
          "moisture" => conditions["moisture"],
          "max_height" => conditions["max_height_cm"] && to_string(conditions["max_height_cm"]),
          # A large area, so the planner returns its widest selection
          "width" => "10",
          "length" => "10"
        })

      plants =
        case conditions["wildlife"] do
          nil -> plants
          goal -> Enum.filter(plants, &supports_wildlife?(&1, goal))
        end

      {:ok,
       %{
         plants:
           plants
           |> Enum.take(@max_results)
           |> Enum.map(&Map.put(summary_json(&1), :fit, fit(&1)))
       }}
    end
  end

  # GardenDesign.recommend/1 adds :fit to each Plant struct it returns.
  defp fit(plant), do: plant |> then(&:maps.get(:fit, &1)) |> to_string()

  defp fetch_required(conditions, key) do
    case conditions[key] do
      nil -> {:error, "#{key} is required"}
      value -> {:ok, value}
    end
  end

  # ── Filter values ───────────────────────────────────────────────────────────

  @doc "Valid values for each search filter."
  def filters do
    plants = Catalog.list_plants()
    heights = plants |> Enum.map(& &1.height_max_cm) |> Enum.reject(&is_nil/1)

    %{
      category: @categories,
      light: @light_levels,
      moisture: @moisture_levels,
      bloom_season: @seasons,
      wildlife: @wildlife |> Map.keys() |> Enum.sort(),
      flower_color:
        Enum.filter(@colours, fn colour ->
          Enum.any?(plants, &contains?(&1.flower_color, colour))
        end),
      height_cm: %{min: Enum.min(heights, fn -> nil end), max: Enum.max(heights, fn -> nil end)},
      deer_resistant: [true, false],
      ontario_native: [true, false],
      max_results: @max_results,
      not_available: "The catalogue has no soil type, price, pot size or stock data."
    }
  end

  # ── Public JSON ─────────────────────────────────────────────────────────────

  @doc "Compact plant summary for search results."
  def summary_json(%Plant{} = plant) do
    %{
      common_name: plant.common_name,
      latin_name: ShelleyPlantsWeb.Seo.latin_name(plant),
      category: plant.category,
      light: plant.sun_level,
      moisture: plant.moisture_level,
      height: plant.height,
      bloom_time: plant.bloom_time,
      flower_color: plant.flower_color,
      native_status: native_status(plant),
      deer_resistant: plant.deer_resistant,
      url: page_url(plant)
    }
    |> tidy()
  end

  @doc """
  Everything the public plant page shows. Leaves out internal fields (the
  database id, timestamps and the planner's moisture tolerances).
  """
  def public_json(%Plant{} = plant) do
    Map.merge(summary_json(plant), %{
      slug: plant.slug,
      plant_type: plant.plant_type,
      light_requirements: plant.light_requirements,
      moisture_notes: plant.moisture,
      height_min_cm: plant.height_min_cm,
      height_max_cm: plant.height_max_cm,
      spread_cm: plant.spread_cm,
      native_to_ontario: plant.native_ontario,
      locally_native: plant.locally_native,
      near_native: plant.near_native,
      chelsea_chop: plant.chelsea_chop,
      ecological_benefit: plant.ecological_benefit,
      notes: plant.notes,
      image_url: plant.picture && ShelleyPlantsWeb.Seo.absolute_url(plant.picture)
    })
    |> tidy()
  end

  # Collapse stray double and non-breaking spaces in text values
  defp tidy(map) do
    Map.new(map, fn
      {k, v} when is_binary(v) -> {k, ShelleyPlantsWeb.Seo.squish(v)}
      pair -> pair
    end)
  end

  defp native_status(plant) do
    cond do
      plant.locally_native -> "locally native"
      plant.native_ontario -> "Ontario native"
      plant.near_native -> "near-native"
      true -> "not native to Ontario"
    end
  end

  defp page_url(plant), do: ShelleyPlantsWeb.Seo.absolute_url("/plants/#{plant.slug}")

  # ── Input handling ──────────────────────────────────────────────────────────

  @keys ~w(query category light moisture min_height_cm max_height_cm bloom_season
           flower_color deer_resistant wildlife ontario_native limit)

  # String keys, known keys only, blank values dropped.
  defp normalize(filters) do
    filters
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
    |> Map.take(@keys)
    |> Map.reject(fn {_k, v} -> v in [nil, ""] end)
  end

  defp validate(filters) do
    Enum.find_value(filters, :ok, fn {key, value} ->
      case check(key, value) do
        :ok -> nil
        {:error, _} = error -> error
      end
    end)
  end

  defp check("category", v), do: one_of(v, @categories, "category")
  defp check("light", v), do: one_of(v, @light_levels, "light")
  defp check("moisture", v), do: one_of(v, @moisture_levels, "moisture")
  defp check("bloom_season", v), do: one_of(v, @seasons, "bloom_season")
  defp check("wildlife", v), do: one_of(v, Map.keys(@wildlife), "wildlife")

  defp check(key, v)
       when key in ~w(min_height_cm max_height_cm limit) and is_integer(v) and v > 0, do: :ok

  defp check(key, _) when key in ~w(min_height_cm max_height_cm limit),
    do: {:error, "#{key} must be a positive whole number"}

  defp check(key, v) when key in ~w(deer_resistant ontario_native) and is_boolean(v), do: :ok

  defp check(key, _) when key in ~w(deer_resistant ontario_native),
    do: {:error, "#{key} must be true or false"}

  defp check(_key, v) when is_binary(v), do: :ok
  defp check(key, _), do: {:error, "#{key} must be text"}

  defp one_of(value, allowed, name) do
    if value in allowed,
      do: :ok,
      else: {:error, "#{name} must be one of: #{Enum.join(allowed, ", ")}"}
  end
end
