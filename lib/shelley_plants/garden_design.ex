defmodule ShelleyPlants.GardenDesign do
  @moduledoc """
  Plant recommendation and garden planning logic for the Design Your Garden feature.
  """

  import Ecto.Query
  alias ShelleyPlants.Repo
  alias ShelleyPlants.Catalog.Plant

  # Sun levels that are compatible with a given garden sun input
  @sun_compat %{
    "full_sun" => ["full_sun", "part_shade"],
    "part_shade" => ["part_shade", "full_sun", "full_shade"],
    "full_shade" => ["full_shade", "part_shade"]
  }

  # ── Public API ────────────────────────────────────────────────────────────────

  # Fit levels, best to worst — drives both the sort order and the colour
  # dot/legend shown next to each recommended plant.
  @fit_colors %{great: "#16a34a", good: "#f59e0b", fallback: "#dc2626"}
  @fit_rank %{great: 0, good: 1, fallback: 2}

  @doc """
  Returns a list of recommended %Plant{} structs based on garden inputs,
  sorted by best fit first, then filtered by sun, moisture, max height, and
  height structure preference. Each plant is decorated with a :quantity,
  :color, and :fit key (:great, :good, or :fallback) for display. Also
  returns a parallel list of :alternates (2-3 plants per primary).

  Moisture affects selection two ways: plants that explicitly can't
  tolerate the garden's moisture (`moisture_unacceptable`) are excluded
  entirely, and among the rest, plants whose `moisture_level` matches are
  preferred.

  Fit is a combination of sun and moisture match:

    * `:great` — sun is an exact match for what was requested, and moisture
      either wasn't requested or matches exactly
    * `:good` — matches on exactly one of sun or moisture (the other is
      only tolerated, not an exact match)
    * `:fallback` — sun is only tolerated (not exact) and moisture doesn't
      match either — the plant is included to fill out the list, not
      because it's a confirmed fit

  Height and structure aren't factored into fit, since candidates outside
  those constraints are already excluded before fit is scored.
  """
  def recommend(inputs) do
    area = garden_area(inputs)
    sun = inputs["sun"]
    moisture = inputs["moisture"]
    max_h = parse_int(inputs["max_height"])
    structure = inputs["height_structure"] || "mixed"

    compatible_sun = Map.get(@sun_compat, sun, ["full_sun", "part_shade", "full_shade"])
    species_limit = species_limit_for_area(area)

    # Fetch all compatible plants, excluding those that can't tolerate the
    # garden's moisture
    base_query =
      from p in Plant,
        where: p.sun_level in ^compatible_sun,
        order_by: [asc: p.height_min_cm]

    query =
      if moisture in [nil, ""] do
        base_query
      else
        from p in base_query, where: ^moisture not in p.moisture_unacceptable
      end

    candidates = Repo.all(query)

    # Apply max height filter
    candidates =
      if max_h && max_h > 0 do
        Enum.filter(candidates, fn p ->
          is_nil(p.height_min_cm) or p.height_min_cm <= max_h
        end)
      else
        candidates
      end

    # Prefer plants whose moisture_level matches the garden's moisture when
    # narrowing the candidate pool down to species_limit, without excluding
    # the rest
    ranked_candidates = prefer_moisture_match(candidates, sun, moisture)

    # Select by height structure, then sort the final list by fit (best
    # first) so the displayed order always reflects match quality
    selected =
      ranked_candidates
      |> select_by_structure(structure, species_limit)
      |> Enum.sort_by(&Map.fetch!(@fit_rank, fit_level(&1, sun, moisture)))

    # Build alternates map: for each selected plant, find similar plants not in selection
    selected_ids = MapSet.new(selected, & &1.id)

    alternates =
      Map.new(selected, fn plant ->
        alts =
          candidates
          |> Enum.reject(&MapSet.member?(selected_ids, &1.id))
          |> Enum.filter(&similar_height?(&1, plant))
          |> Enum.take(3)

        {plant.id, alts}
      end)

    # Decorate each plant with quantity, fit, and the fit colour
    decorated =
      Enum.map(selected, fn plant ->
        qty = suggested_quantity(plant, area, length(selected))
        fit = fit_level(plant, sun, moisture)

        Map.merge(plant, %{quantity: qty, fit: fit, color: Map.fetch!(@fit_colors, fit)})
      end)

    {decorated, alternates}
  end

  @doc """
  Returns the fit colour map for use in the results legend.
  """
  def fit_colors, do: @fit_colors

  # ── Selection logic ───────────────────────────────────────────────────────────

  defp select_by_structure(candidates, "low_uniform", limit) do
    candidates
    |> Enum.filter(&((&1.height_max_cm || 999) <= 91))
    |> diverse_sample(limit)
    |> fallback_if_empty(candidates, limit)
  end

  defp select_by_structure(candidates, "layered", limit) do
    # Mix of short (≤61cm), mid (61-122cm), tall (>122cm)
    short = Enum.filter(candidates, &((&1.height_max_cm || 0) <= 61))

    mid =
      Enum.filter(candidates, &((&1.height_min_cm || 0) > 30 and (&1.height_max_cm || 0) <= 122))

    tall = Enum.filter(candidates, &((&1.height_min_cm || 0) >= 91))

    thirds = max(div(limit, 3), 1)

    (Enum.take(short, thirds) ++ Enum.take(mid, thirds) ++ Enum.take(tall, limit - thirds * 2))
    |> Enum.uniq_by(& &1.id)
    |> fallback_if_empty(candidates, limit)
  end

  defp select_by_structure(candidates, "focal", limit) do
    focal = candidates |> Enum.filter(&((&1.height_min_cm || 0) >= 91)) |> Enum.take(2)

    supporting =
      candidates
      |> Enum.reject(&((&1.height_min_cm || 0) >= 91))
      |> diverse_sample(limit - length(focal))

    (focal ++ supporting) |> Enum.uniq_by(& &1.id)
  end

  defp select_by_structure(candidates, _mixed, limit) do
    diverse_sample(candidates, limit)
  end

  # Pick a diverse set across categories, preferring plants with photos
  defp diverse_sample(plants, limit) do
    with_photo = Enum.filter(plants, & &1.picture)
    without_photo = Enum.reject(plants, & &1.picture)
    ordered = with_photo ++ without_photo

    ordered
    |> Enum.group_by(& &1.category)
    |> Enum.flat_map(fn {_cat, ps} -> Enum.take(ps, max(div(limit, 4), 1)) end)
    |> Enum.take(limit)
    |> then(fn selected ->
      if length(selected) < limit do
        extra = ordered -- selected
        selected ++ Enum.take(extra, limit - length(selected))
      else
        selected
      end
    end)
  end

  defp fallback_if_empty([], candidates, limit), do: diverse_sample(candidates, limit)
  defp fallback_if_empty(list, _candidates, _limit), do: list

  # Stable-sorts candidates so the best-fitting plants (see fit_level/3) come
  # first, without dropping worse-fitting ones — used to bias which plants
  # get selected when the candidate pool is larger than species_limit.
  defp prefer_moisture_match(candidates, sun, moisture) do
    Enum.sort_by(candidates, &Map.fetch!(@fit_rank, fit_level(&1, sun, moisture)))
  end

  # Combined sun + moisture fit for a single plant against the requested
  # garden conditions. See the `fit` field doc on recommend/1 for the rules.
  defp fit_level(plant, sun, moisture) do
    sun_exact? = sun in [nil, ""] or plant.sun_level == sun
    moisture_exact? = moisture in [nil, ""] or plant.moisture_level == moisture

    cond do
      sun_exact? and moisture_exact? -> :great
      sun_exact? or moisture_exact? -> :good
      true -> :fallback
    end
  end

  # ── Quantity calculation ──────────────────────────────────────────────────────

  defp suggested_quantity(plant, area_m2, species_count) do
    spread_m = (plant.spread_cm || 45) / 100.0
    # Each plant occupies roughly spread² area; divide total area among species
    area_per_species = area_m2 / max(species_count, 1)
    qty = ceil(area_per_species / (spread_m * spread_m))
    qty |> max(1) |> min(20)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp garden_area(inputs) do
    w = parse_float(inputs["width"])
    l = parse_float(inputs["length"])
    if w > 0 and l > 0, do: Float.round(w * l, 1), else: 10.0
  end

  defp species_limit_for_area(area) do
    cond do
      area < 5 -> 4
      area < 15 -> 6
      area < 30 -> 8
      true -> 10
    end
  end

  defp similar_height?(candidate, plant) do
    c_min = candidate.height_min_cm || 60
    p_min = plant.height_min_cm || 60
    abs(c_min - p_min) <= 40
  end

  defp parse_float(nil), do: 0.0
  defp parse_float(""), do: 0.0

  defp parse_float(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> f
      :error -> 0.0
    end
  end

  defp parse_float(v) when is_number(v), do: v * 1.0

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {i, _} -> i
      :error -> nil
    end
  end
end
