defmodule ShelleyPlants.MCP.Public.SearchPlants do
  @moduledoc """
  Search the Ontario native plants sold by Biosphere Native Plants, a native
  plant nursery near Westport in Eastern Ontario, Canada. Combine any filters;
  all are optional. Returns up to 25 plants (common and Latin name, category,
  light, moisture, height, bloom time, flower colour, native status) with a
  link to each plant's page, plus the total number of matches. Call
  list_filters first to see valid filter values. Price and stock aren't
  available.
  """

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.MCP.Public.Reply
  alias ShelleyPlants.PlantSearch

  schema do
    field :query, :string, description: "Text in the common or Latin name, e.g. \"aster\""

    field :category, :enum,
      values: ["Wildflower", "Grass", "Shrub", "Tree"],
      description: "Plant category"

    field :light, :enum,
      values: ["full_sun", "part_shade", "full_shade"],
      description: "Preferred light"

    field :moisture, :enum,
      values: ["wet", "average", "dry", "very_dry"],
      description: "Preferred soil moisture"

    field :min_height_cm, :integer, description: "Mature height reaches at least this many cm"
    field :max_height_cm, :integer, description: "Mature height stays at most this many cm"

    field :bloom_season, :enum,
      values: ["spring", "summer", "fall"],
      description: "Blooms during this season"

    field :flower_color, :string, description: "Text in the flower colour, e.g. \"yellow\""
    field :deer_resistant, :boolean, description: "Only deer-resistant plants (true)"

    field :wildlife, :enum,
      values: [
        "pollinators",
        "bees",
        "butterflies",
        "moths",
        "hummingbirds",
        "birds",
        "host_plant"
      ],
      description: "Supports this wildlife (from the plant's ecological benefit)"

    field :ontario_native, :boolean, description: "Only plants native to Ontario (true)"
    field :limit, :integer, description: "Maximum results, up to 25 (default 25)"
  end

  @impl true
  def execute(params, frame) do
    params |> PlantSearch.search() |> Reply.result(frame)
  end
end
