defmodule ShelleyPlants.Repo.Migrations.PrepopulatePlantStructuredFields do
  use Ecto.Migration

  # Best-guess values derived from existing height/light/moisture text fields.
  # Shelley should review and correct via the admin edit form.
  # Heights converted from inches to cm (x 2.54, rounded to nearest 5cm).
  # Matched by latin_name (unique-constrained) so this works across all environments.
  # sun_level:      full_sun | part_shade | full_shade
  # moisture_level: dry | average | moist | wet
  # spread_cm:      typical garden spread (estimate — review if incorrect)

  @plants [
    # {latin_name, height_min_cm, height_max_cm, spread_cm, sun_level, moisture_level}

    # Great Blue Lobelia — 24-36", sun to part shade, average to wet
    {"Lobelia siphilitica", 61, 91, 45, "part_shade", "moist"},
    # Sky Blue Aster — 24-36", full sun, average to dry
    {"Symphyotrichum oolentangiense", 61, 91, 45, "full_sun", "dry"},
    # Nodding Onion — 24-36", full sun, average to dry
    {"Allium cernuum", 61, 91, 30, "full_sun", "dry"},
    # Yellow Giant Hyssop — 36-72", full sun to part shade, average to moist
    {"Agastache nepetoides", 91, 183, 60, "part_shade", "average"},
    # Foxglove Beardtongue — 24-36", full sun, average to dry
    {"Penstemon digitalis", 61, 91, 45, "full_sun", "dry"},
    # Hairy Beardtongue — 18-24", full sun to full shade, moderately dry to wet
    {"Penstemon hirsutus", 46, 61, 40, "part_shade", "average"},
    # Canada Columbine — 12-24", full sun to part shade, average to dry
    {"Aquilegia canadensis", 30, 61, 30, "part_shade", "dry"},
    # Anise Hyssop — 24-48", full sun to part shade, average to moderately dry
    {"Agastache foeniculum", 61, 122, 45, "full_sun", "dry"},
    # Wild Lupine — 12-24", full sun (tolerates light shade), average to dry
    {"Lupinus perennis", 30, 61, 30, "full_sun", "dry"},
    # Black-eyed Susan — 12-36", full sun, average to dry
    {"Rudbeckia hirta", 30, 91, 40, "full_sun", "dry"},
    # Prairie Smoke — 12", full sun to part shade, average to moderately dry
    {"Geum triflorum", 30, 30, 30, "full_sun", "dry"},
    # Wild Bergamot — 24-48", full sun to part shade, average to dry
    {"Monarda fistulosa", 61, 122, 45, "part_shade", "dry"},
    # Showy Tick Trefoil — 24-60", full sun to part shade, average
    {"Desmodium canadense", 61, 152, 60, "full_sun", "average"},
    # Pearly Everlasting — 12-24", full sun to part shade, average to dry
    {"Anaphalis margaritacea", 30, 61, 40, "full_sun", "dry"},
    # Tall Bellflower — 24-72", part to full shade, moist to wet
    {"Campanulastrum americanum", 61, 183, 45, "part_shade", "moist"},
    # Hair Wood Mint — 18-36", part sun to full shade, average to moist
    {"Blephilia hirsuta", 46, 91, 40, "full_shade", "moist"},
    # Swamp Milkweed — 36-60", full sun to part shade, average to wet
    {"Asclepias incarnata", 91, 152, 60, "full_sun", "moist"},
    # Pale Purple Coneflower — 36-60", full sun, average to dry
    {"Echinacea pallida", 91, 152, 45, "full_sun", "dry"},
    # Bottlebrush Grass — 24-48", partial sun to full shade, dry to medium
    {"Elymus hystrix", 61, 122, 45, "full_shade", "dry"},
    # Smooth Blue Aster — 24-48", full sun to part shade, average to dry
    {"Symphyotrichum laeve", 61, 122, 45, "full_sun", "dry"},
    # Grey-headed Coneflower — 36-60", full sun (tolerates partial), average to dry
    {"Ratibida pinnata", 91, 152, 45, "full_sun", "dry"},
    # Downy Wood Mint — 12-24", full sun to part shade, average to dry
    {"Blephilia ciliata", 30, 61, 35, "part_shade", "dry"},
    # 3-lobed Black-eyed Susan — 24-60", full sun to partial shade, average
    {"Rudbeckia triloba", 61, 152, 60, "part_shade", "average"},
    # Common Sneezeweed — 24-48", full sun, moist to wet
    {"Helenium autumnale", 61, 122, 45, "full_sun", "wet"},
    # Little Bluestem — 12-36", full sun only, average to dry
    {"Schizachyrium scoparium", 30, 91, 45, "full_sun", "dry"},
    # Obedient Plant — 24-48", full sun to part shade, medium to wet
    {"Physostegia virginiana", 61, 122, 60, "full_sun", "moist"},
    # False Yellow Sorghum — 36-60", full sun, dry to medium
    {"Sorghastrum nutans", 91, 152, 60, "full_sun", "dry"},
    # New England Aster — 24-48", full sun (tolerates partial), medium to moist
    {"Symphyotrichum novae-angliae", 61, 122, 60, "full_sun", "moist"},
    # Cut-leaf Coneflower — 36-72", full sun to full shade, average to wet
    {"Rudbeckia laciniata", 91, 183, 90, "part_shade", "wet"},
    # Lance-leaved Heal All — 4-12", full sun to part shade, average to dry
    {"Prunella vulgaris var. lanceolata", 10, 30, 20, "part_shade", "dry"},
    # Spotted Bee Balm — 12-36", full sun, medium to dry
    {"Monarda punctata", 30, 91, 45, "full_sun", "dry"},
    # Prairie Dropseed — 12-16" base (stalks 24-36"), full sun, dry
    {"Sporobolus heterolepis", 30, 41, 30, "full_sun", "dry"},
    # Rough Blazing Star — 24-48", full sun, average to dry
    {"Liatris aspera", 61, 122, 40, "full_sun", "dry"},
    # Pale Corydalis — 12-36", full sun to part shade, average to very dry
    {"Capnoides sempervirens", 30, 91, 30, "full_sun", "dry"},
    # White Prairie Clover — 12-36", full sun, average to dry
    {"Dalea candida", 30, 91, 35, "full_sun", "dry"},
    # Canada Wild Rye — 24-60", full sun to partial shade, versatile
    {"Elymus canadensis", 61, 152, 60, "part_shade", "average"},
    # Spotted Joe Pye Weed — 48-84", full sun to part shade, average to wet
    {"Eutrochium maculatum", 122, 213, 90, "full_sun", "moist"},
    # Big Bluestem — 48-96", full sun (tolerates partial), dry to medium
    {"Andropogon gerardii", 122, 244, 75, "full_sun", "dry"},
    # Lance-leaved Coreopsis — 12-36", full sun, average to dry
    {"Coreopsis lanceolata", 30, 91, 40, "full_sun", "dry"},
    # Upland White Goldenrod — 12-24", full sun, average to dry
    {"Oligoneuron album (formerlh called Solidago ptarmicoides)", 30, 61, 45, "full_sun", "dry"},
    # Prairie Coneflower — 12-36", full sun, average to dry
    {"Ratibida columnifera", 30, 91, 40, "full_sun", "dry"}
  ]

  def up do
    for {latin_name, h_min, h_max, spread, sun, moisture} <- @plants do
      execute """
        UPDATE plants
        SET
          height_min_cm  = #{h_min},
          height_max_cm  = #{h_max},
          spread_cm      = #{spread},
          sun_level      = '#{sun}',
          moisture_level = '#{moisture}'
        WHERE latin_name = '#{latin_name}'
      """
    end
  end

  def down do
    execute """
      UPDATE plants
      SET height_min_cm = NULL, height_max_cm = NULL, spread_cm = NULL,
          sun_level = NULL, moisture_level = NULL
    """
  end
end
