# Design Your Garden — Feature Overview & Implementation Plan

## What it is

A tool that lets visitors describe their garden space and receive a personalised native plant recommendation — including a plant purchase list, suggested quantities, and a visual planting diagram.

It is the flagship interactive feature of the site: something a customer can use on their phone in a garden centre parking lot, at home planning a new bed, or at a Shelley workshop.

---

## Current status (as of 2026-06-22)

| Layer | Status |
|---|---|
| UI form (5 sections) | ✅ Built — `/design-garden` |
| Mock results (6 hardcoded plants) | ✅ Built |
| New DB columns for matching | ✅ Migrated |
| Admin form updated with new fields | ✅ Done |
| Real plant-matching query | 🔲 Not started |
| Rich results output (3 panels) | 🔲 Not started |
| SVG planting diagram | 🔲 Not started |
| Save design to customer profile | 🔲 Not started — Phase 2 |

---

## Form inputs (what the customer tells us)

| Field | UI control | Used for |
|---|---|---|
| Width (m) | Number input | Area calculation, plant count |
| Length (m) | Number input | Area calculation, plant count |
| Shape | SVG icon selector | Planting diagram shape |
| Max height (cm) | Number input | Filter out tall plants |
| Height structure | Card selector | Sort/arrange plant selection |
| Sun exposure | Icon card selector | Filter by `sun_level` |

---

## Results output (what the customer gets) — to be built

### Panel 1 — Summary card
One paragraph recapping inputs: space size, shape, sun, structure preference, and a count of recommended species.

### Panel 2 — Plant purchase list
A clean table/list of each recommended plant showing:
- Common name + latin name
- Height range
- Spread
- Suggested quantity (calculated from garden area ÷ spread²)
- Category badge (Wildflower / Grass / Shrub / Tree)
- Photo thumbnail

Quantity logic:
```
spacing_m = plant.spread_cm / 100
plants_per_sqm = 1 / (spacing_m * spacing_m)
quantity = ceil(garden_area_sqm * plants_per_sqm / total_species_count)
minimum = 1, maximum capped at ~20 per species
```

### Panel 3 — Planting diagram
An SVG drawn from the garden shape (width × length) with plants shown as colour-coded circles, sized proportionally to their spread. Legend beside the diagram maps colour to common name. Heights drive placement: tall plants to the rear for "layered" structure, scattered for "mixed/naturalistic", etc.

---

## Plant matching logic — to be built

File: `lib/shelley_plants/garden_design.ex` (new module)
Function: `GardenDesign.recommend_plants(inputs)` → `[%Plant{}]`

### Matching rules
1. **Sun filter** — match `plant.sun_level` to customer's `sun` input. A `full_sun` plant is excluded from a `full_shade` garden. `part_shade` plants appear in both sun and shade gardens.
2. **Height filter** — exclude plants where `height_min_cm > max_height_cm` input (if provided).
3. **Quantity limit** — use garden area to cap how many species are returned. Rough guide: <5m² → 4 species, 5–15m² → 6–8, 15–30m² → 8–12, 30m²+ → 12–16.
4. **Height structure sort** — after filtering, order plants:
   - `low_uniform` → sort by `height_max_cm` asc, take short plants
   - `layered` → include a mix of heights, sorted short to tall
   - `mixed` → shuffle / varied selection
   - `focal` → include 1–2 tall anchor plants + supporting mid/low plants
5. **Diversity** — aim for a mix of categories (not all Wildflowers). Prefer plants with photos.

### Sun level matching matrix
| Customer selects | Plants included |
|---|---|
| Full sun | `full_sun`, `part_shade` |
| Part shade | `part_shade`, `full_sun` (tolerant ones), `full_shade` |
| Full shade | `full_shade`, `part_shade` |

---

## Phase 2 — Save to customer profile

### What's needed
- New `garden_designs` DB table: `id`, `user_id` (FK → users), `name` (e.g. "Front bed design"), `inputs` (jsonb), `plant_ids` (array or join table), `inserted_at`
- "Save this design" button on results page (visible when logged in)
- Guest nudge: "Log in to save this design"
- "My Designs" page at `/my-designs` listing saved plans with name, date, size summary
- Each saved design links back to its full results view

### Not yet started — no DB schema exists for this

---

## Key files

| File | Purpose |
|---|---|
| `lib/shelley_plants_web/live/garden_live/design.ex` | Main LiveView — form + results |
| `lib/shelley_plants/catalog.ex` | Add `recommend_plants/1` here |
| `lib/shelley_plants/catalog/plant.ex` | Schema — new structured fields added |
| `test/shelley_plants_web/live/garden_live_test.exs` | 10 tests — update when real logic lands |
| `docs/plant_data_guide_for_shelley.md` | Data entry guide for new fields |

---

## Notes & decisions log

- **Heights stored in inches** in the original `height` text field (e.g. `"24-36"`). The new `height_min_cm` / `height_max_cm` integer fields replace this for matching — the original display text field is kept unchanged.
- **Light requirements** are freeform paragraphs in the DB. The new `sun_level` enum replaces this for matching — original field kept for display.
- **Spread** is not in the original data at all — Shelley needs to supply this for all plants.
- Sun exposure was added to the design form (section 5) even though it wasn't in the original brief, since the plant data already has it and it's the single most important matching criterion.
