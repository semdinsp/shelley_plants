defmodule ShelleyPlants.MCP.Public.RecommendPlants do
  @moduledoc """
  Recommend Ontario native plants from Biosphere Native Plants (Eastern
  Ontario, Canada) for a garden's conditions, using the same matching as the
  site's garden planner. Give the light (required), and optionally the soil
  moisture, a maximum height and a wildlife goal. Each plant comes with a fit:
  "great" (matches light and moisture), "good" (matches one) or "fallback".
  Use search_plants instead to filter on exact attributes.
  """

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.MCP.Public.Reply
  alias ShelleyPlants.PlantSearch

  schema do
    field :light, :enum,
      required: true,
      values: ["full_sun", "part_shade", "full_shade"],
      description: "The garden's light"

    field :moisture, :enum,
      values: ["wet", "average", "dry", "very_dry"],
      description: "The garden's soil moisture"

    field :max_height_cm, :integer, description: "Tallest plant wanted, in cm"

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
      description: "Wildlife to support"
  end

  @impl true
  def execute(params, frame) do
    params |> PlantSearch.recommend() |> Reply.result(frame)
  end
end
