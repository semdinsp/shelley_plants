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
    "#f43f5e",
    "#f97316",
    "#f59e0b",
    "#84cc16",
    "#10b981",
    "#06b6d4",
    "#3b82f6",
    "#8b5cf6",
    "#ec4899",
    "#14b8a6",
    "#eab308",
    "#ef4444"
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
            Map.get(
              @category_colors,
              plant.category,
              Enum.at(@plant_palette, rem(idx, palette_size))
            )
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

  # ── Quantity calculation ──────────────────────────────────────────────────────

  defp suggested_quantity(plant, area_m2, species_count) do
    spread_m = (plant.spread_cm || 45) / 100.0
    # Each plant occupies roughly spread² area; divide total area among species
    area_per_species = area_m2 / max(species_count, 1)
    qty = ceil(area_per_species / (spread_m * spread_m))
    qty |> max(1) |> min(20)
  end

  # ── Diagram placement ─────────────────────────────────────────────────────────

  defp place_plants(plants, canvas_w, canvas_h, scale, _shape, structure) do
    # Expand each species into individual instances, one circle per plant
    instances =
      plants
      |> Enum.flat_map(fn plant ->
        Enum.map(1..plant.quantity, fn _ ->
          %{
            spread_cm: plant.spread_cm || 40,
            color: plant.color || "#4ade80",
            label: plant.common_name,
            height_min_cm: plant.height_min_cm || 60
          }
        end)
      end)

    # Sort by height for layered structure (tallest first = back of diagram)
    instances =
      if structure == "layered" do
        Enum.sort_by(instances, & &1.height_min_cm, :desc)
      else
        instances
      end

    total = length(instances)

    # Use the smallest spread to set circle radius — keeps diagram readable
    # Cap radius so circles fit the canvas even for large quantities
    min_spread = instances |> Enum.map(& &1.spread_cm) |> Enum.min(fn -> 40 end)
    r_from_spread = max(round(min_spread * scale / 100 / 2 * 80), 6)

    # Also cap radius so all circles fit: grid cell size = canvas / sqrt(total)
    r_from_grid =
      if total > 0 do
        cell = :math.sqrt(canvas_w * canvas_h / total)
        max(round(cell / 2 * 0.85), 6)
      else
        r_from_spread
      end

    r = min(r_from_spread, r_from_grid)
    margin = r + 3

    usable_w = max(canvas_w - margin * 2, 1)
    usable_h = max(canvas_h - margin * 2, 1)
    cols = max(ceil(:math.sqrt(total * canvas_w / max(canvas_h, 1))), 1)
    rows = max(ceil(total / cols), 1)

    Enum.with_index(instances)
    |> Enum.map(fn {inst, idx} ->
      row = div(idx, cols)
      col = rem(idx, cols)
      # Offset every other row for a natural staggered look
      offset = if rem(row, 2) == 1, do: round(usable_w / cols / 2), else: 0
      x = margin + offset + round(col * usable_w / cols + usable_w / (cols * 2))
      y = margin + round(row * usable_h / max(rows, 1) + usable_h / (rows * 2))

      %{
        x: clamp(x, margin, canvas_w - margin),
        y: clamp(y, margin, canvas_h - margin),
        r: r,
        color: inst.color,
        label: inst.label
      }
    end)
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
