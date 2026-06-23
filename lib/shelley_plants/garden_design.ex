defmodule ShelleyPlants.GardenDesign do
  @moduledoc """
  Plant recommendation and garden planning logic for the Design Your Garden feature.
  """

  import Ecto.Query
  alias ShelleyPlants.Repo
  alias ShelleyPlants.Catalog.Plant

  # Category colours used in the legend (when category is populated)
  @category_colors %{
    "Wildflower" => "#f43f5e",
    "Grass" => "#f59e0b",
    "Shrub" => "#8b5cf6",
    "Tree" => "#06b6d4",
    nil => "#94a3b8"
  }

  # Vibrant per-plant palette — cycles through when category is nil or repeated
  @plant_palette [
    "#f43f5e", "#f97316", "#f59e0b", "#84cc16",
    "#10b981", "#06b6d4", "#3b82f6", "#8b5cf6",
    "#ec4899", "#14b8a6", "#eab308", "#ef4444"
  ]

  # Sun levels that are compatible with a given garden sun input
  @sun_compat %{
    "full_sun" => ["full_sun", "part_shade"],
    "part_shade" => ["part_shade", "full_sun", "full_shade"],
    "full_shade" => ["full_shade", "part_shade"]
  }

  # ── Public API ────────────────────────────────────────────────────────────────

  @doc """
  Returns a list of recommended %Plant{} structs based on garden inputs,
  sorted and filtered by sun, max height, and height structure preference.
  Each plant is decorated with a :quantity and :color key for display.
  Also returns a parallel list of :alternates (2-3 plants per primary).
  """
  def recommend(inputs) do
    area = garden_area(inputs)
    sun = inputs["sun"]
    max_h = parse_int(inputs["max_height"])
    structure = inputs["height_structure"] || "mixed"

    compatible_sun = Map.get(@sun_compat, sun, ["full_sun", "part_shade", "full_shade"])
    species_limit = species_limit_for_area(area)

    # Fetch all compatible plants
    candidates =
      Repo.all(
        from p in Plant,
          where: p.sun_level in ^compatible_sun,
          order_by: [asc: p.height_min_cm]
      )

    # Apply max height filter
    candidates =
      if max_h && max_h > 0 do
        Enum.filter(candidates, fn p ->
          is_nil(p.height_min_cm) or p.height_min_cm <= max_h
        end)
      else
        candidates
      end

    # Sort and select by height structure
    selected = select_by_structure(candidates, structure, species_limit)

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

    # Decorate each plant with quantity and colour
    palette_size = length(@plant_palette)

    decorated =
      Enum.with_index(selected)
      |> Enum.map(fn {plant, idx} ->
        qty = suggested_quantity(plant, area, length(selected))
        color =
          if plant.category && plant.category != "" do
            Map.get(@category_colors, plant.category, Enum.at(@plant_palette, rem(idx, palette_size)))
          else
            Enum.at(@plant_palette, rem(idx, palette_size))
          end
        Map.merge(plant, %{quantity: qty, color: color})
      end)

    {decorated, alternates}
  end

  @doc """
  Returns the category colour map for use in the diagram legend.
  """
  def category_colors, do: @category_colors

  @doc """
  Builds SVG planting diagram data: a list of plant circles with x/y/r positions
  within the garden shape bounds. Returns {width_px, height_px, circles}.
  """
  def diagram_data(plants, inputs) do
    width_m = parse_float(inputs["width"])
    length_m = parse_float(inputs["length"])
    shape = inputs["shape"] || "rectangular"

    # Scale to fit in ~500px wide canvas, maintaining aspect ratio
    scale = if width_m > 0, do: min(500 / (width_m * 100), 3.0), else: 1.0
    canvas_w = round(width_m * 100 * scale)
    canvas_h = round(length_m * 100 * scale)

    structure = inputs["height_structure"] || "mixed"
    circles = place_plants(plants, canvas_w, canvas_h, scale, shape, structure)

    {canvas_w, canvas_h, circles}
  end

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
    mid = Enum.filter(candidates, &((&1.height_min_cm || 0) > 30 and (&1.height_max_cm || 0) <= 122))
    tall = Enum.filter(candidates, &((&1.height_min_cm || 0) >= 91))

    thirds = max(div(limit, 3), 1)
    (Enum.take(short, thirds) ++ Enum.take(mid, thirds) ++ Enum.take(tall, limit - thirds * 2))
    |> Enum.uniq_by(& &1.id)
    |> fallback_if_empty(candidates, limit)
  end

  defp select_by_structure(candidates, "focal", limit) do
    focal = candidates |> Enum.filter(&((&1.height_min_cm || 0) >= 91)) |> Enum.take(2)
    supporting = candidates |> Enum.reject(&((&1.height_min_cm || 0) >= 91)) |> diverse_sample(limit - length(focal))
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

  # ── Quantity calculation ──────────────────────────────────────────────────────

  defp suggested_quantity(plant, area_m2, species_count) do
    spread_m = (plant.spread_cm || 45) / 100.0
    # Each plant occupies roughly spread² area; divide total area among species
    area_per_species = area_m2 / max(species_count, 1)
    qty = ceil(area_per_species / (spread_m * spread_m))
    qty |> max(1) |> min(20)
  end

  # ── Diagram placement ─────────────────────────────────────────────────────────

  defp place_plants(plants, canvas_w, canvas_h, scale, shape, structure) do
    Enum.with_index(plants)
    |> Enum.map(fn {plant, idx} ->
      r = max(round((plant.spread_cm || 40) * scale / 100 / 2 * 80), 8)
      {x, y} = plant_position(idx, length(plants), canvas_w, canvas_h, r, shape, structure, plant)
      %{
        x: x, y: y, r: r,
        color: plant.color || "#4ade80",
        label: plant.common_name,
        latin: plant.latin_name,
        quantity: plant.quantity
      }
    end)
  end

  defp plant_position(idx, total, w, h, r, _shape, structure, plant) do
    margin = r + 4
    usable_w = max(w - margin * 2, 1)
    usable_h = max(h - margin * 2, 1)

    case structure do
      "layered" ->
        # Arrange in rows by height: tall at back (top), short at front (bottom)
        row_count = max(ceil(total / 3), 1)
        row = floor(idx / 3)
        col = rem(idx, 3)
        cols_in_row = min(total - row * 3, 3)
        x = margin + round(col * usable_w / max(cols_in_row, 1) + usable_w / max(cols_in_row * 2, 1))
        y_frac = if row_count > 1, do: row / (row_count - 1), else: 0.5
        # Taller plants (larger height_min_cm) go to the back (top = y small)
        height_frac = normalize_height(plant, 0.1, 0.9)
        y = margin + round(height_frac * usable_h * y_frac + (1 - y_frac) * usable_h * 0.1)
        {clamp(x, margin, w - margin), clamp(y, margin, h - margin)}

      _ ->
        # Grid layout with slight offset for odd rows
        cols = max(ceil(:math.sqrt(total * w / max(h, 1))), 1)
        rows = max(ceil(total / cols), 1)
        row = div(idx, cols)
        col = rem(idx, cols)
        offset = if rem(row, 2) == 1, do: round(usable_w / cols / 2), else: 0
        x = margin + offset + round(col * usable_w / cols + usable_w / (cols * 2))
        y = margin + round(row * usable_h / max(rows, 1) + usable_h / (rows * 2))
        {clamp(x, margin, w - margin), clamp(y, margin, h - margin)}
    end
  end

  defp normalize_height(plant, min_out, max_out) do
    h = plant.height_min_cm || 60
    # Normalise 10-250cm range to min_out..max_out
    frac = (h - 10) / max(250 - 10, 1)
    min_out + frac * (max_out - min_out)
  end

  defp clamp(val, lo, hi), do: val |> max(lo) |> min(hi)

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
