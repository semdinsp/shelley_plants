defmodule ShelleyPlantsWeb.Admin.PlantExportController do
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.Catalog

  @doc """
  Exports all plants as a downloadable JSON file.

  The format matches `plant_import_format.md` and is compatible with
  `mix plants.import`.
  """
  def export(conn, _params) do
    plants = Catalog.list_plants()
    filename = "plants_#{Date.utc_today()}.json"

    json_data =
      plants
      |> Enum.map(&plant_to_map/1)
      |> Jason.encode!(pretty: true)

    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, json_data)
  end

  # Serialises a Plant struct to the canonical import/export format defined
  # in plant_import_format.md. Field order matches the format document.
  defp plant_to_map(plant) do
    %{
      "common_name" => plant.common_name,
      "latin_name" => plant.latin_name,
      "plant_type" => plant.plant_type,
      "flower_color" => plant.flower_color,
      "bloom_time" => plant.bloom_time,
      "height" => plant.height,
      "light_requirements" => plant.light_requirements,
      "moisture" => plant.moisture,
      "chelsea_chop" => plant.chelsea_chop,
      "native_ontario" => plant.native_ontario,
      "locally_native" => plant.locally_native,
      "deer_resistant" => plant.deer_resistant,
      "ecological_benefit" => plant.ecological_benefit,
      "notes" => plant.notes,
      "picture" => plant.picture
    }
  end
end
