defmodule ShelleyPlants.Repo.Migrations.ReplaceMoistWithWetMoistureLevel do
  use Ecto.Migration

  # Moisture levels changed from dry | average | moist | wet to
  # wet | average | dry | very_dry. "moist" plants move to "wet".
  # "very_dry" starts empty and is assigned per plant by hand.

  def up do
    execute "UPDATE plants SET moisture_level = 'wet' WHERE moisture_level = 'moist'"

    # Swap "moist" for "wet" in moisture_unacceptable, without duplicating
    # "wet" when a plant already listed both.
    execute """
    UPDATE plants
    SET moisture_unacceptable = ARRAY(
      SELECT DISTINCT unnest(array_replace(moisture_unacceptable, 'moist', 'wet'))
    )
    WHERE 'moist' = ANY(moisture_unacceptable)
    """
  end

  # "moist" and "wet" can't be told apart after up/0; on rollback only the
  # new "very_dry" level is folded back into "dry".
  def down do
    execute "UPDATE plants SET moisture_level = 'dry' WHERE moisture_level = 'very_dry'"

    execute """
    UPDATE plants
    SET moisture_unacceptable = ARRAY(
      SELECT DISTINCT unnest(array_replace(moisture_unacceptable, 'very_dry', 'dry'))
    )
    WHERE 'very_dry' = ANY(moisture_unacceptable)
    """
  end
end
