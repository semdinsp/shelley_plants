defmodule ShelleyPlantsWeb.GardenExportController do
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.GardenDesign

  @doc """
  Exports the Design Your Garden plant recommendations as a downloadable CSV.

  Re-derives the recommendation from the same form inputs used on
  `/design-garden` (passed as query params), since `GardenDesign.recommend/1`
  is deterministic for a given set of inputs and DB state.
  """
  def export(conn, params) do
    {plants, _alternates} = GardenDesign.recommend(params)
    filename = "garden_plant_list_#{Date.utc_today()}.csv"

    csv_data =
      [csv_row(["Common Name", "Latin Name", "Category", "Quantity", "Height (cm)", "Sun"])] ++
        Enum.map(plants, &plant_csv_row/1) ++
        [
          csv_row([]),
          csv_row([
            "Created by:",
            "Biosphere Native Plants",
            "biosphere-native-plants.ca",
            "613-617-6524"
          ])
        ]

    csv_data = Enum.join(csv_data, "")

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, csv_data)
  end

  defp plant_csv_row(plant) do
    height =
      case {plant.height_min_cm, plant.height_max_cm} do
        {nil, nil} -> ""
        {min, nil} -> "#{min}"
        {nil, max} -> "#{max}"
        {min, max} -> "#{min}-#{max}"
      end

    csv_row([
      plant.common_name,
      plant.latin_name,
      plant.category,
      plant.quantity,
      height,
      human_sun(plant.sun_level)
    ])
  end

  defp human_sun("full_sun"), do: "Full sun"
  defp human_sun("part_shade"), do: "Part shade"
  defp human_sun("full_shade"), do: "Full shade"
  defp human_sun(_), do: ""

  defp csv_row(fields) do
    fields
    |> Enum.map(&csv_escape/1)
    |> Enum.join(",")
    |> Kernel.<>("\r\n")
  end

  defp csv_escape(nil), do: ""

  defp csv_escape(field) do
    value = to_string(field)

    if String.contains?(value, [",", "\"", "\n", "\r"]) do
      ~s("#{String.replace(value, "\"", "\"\"")}")
    else
      value
    end
  end
end
