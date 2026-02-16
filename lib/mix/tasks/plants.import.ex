defmodule Mix.Tasks.Plants.Import do
  @shortdoc "Import plants from a JSON file into the database"

  @moduledoc """
  Imports plant records from a JSON file into the plants table.

  Records are validated through the `ShelleyPlants.Catalog.Plant` changeset.
  Existing records are upserted by `latin_name` (the unique key). If a plant
  with the same `latin_name` already exists, all other fields will be updated.

  ## Usage

      mix plants.import PATH_TO_FILE.json

  ## Exit codes

  - `0` — all records were imported successfully (or upserted).
  - `1` — one or more records failed validation or database insertion.

  ## JSON format

  The file must contain a JSON array of objects. See `plant_import_format.md`
  for the full field reference.

  ## Example

      mix plants.import priv/data/plants.json

  ## Production (Fly.io)

  Use the release eval command instead of mix:

      fly ssh console --pty -C \\
        "/app/bin/shelley_plants eval 'ShelleyPlants.Release.import_plants([\\\"/tmp/plants_import.json\\\"])'"
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    ShelleyPlants.PlantImporter.run(args)
  end
end
