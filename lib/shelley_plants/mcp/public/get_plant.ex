defmodule ShelleyPlants.MCP.Public.GetPlant do
  @moduledoc """
  Get full public details of one Ontario native plant sold by Biosphere
  Native Plants (Eastern Ontario, Canada): growing conditions, height and
  spread, bloom time, flower colour, native status, ecological benefits,
  notes, photo and page URL. Look it up by slug (e.g. "aquilegia-canadensis",
  as returned by search_plants) or by Latin name (e.g. "Aquilegia canadensis").
  """

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.MCP.Public.Reply
  alias ShelleyPlants.PlantSearch

  schema do
    field :plant, :string,
      required: true,
      description: "Slug (\"aquilegia-canadensis\") or Latin name (\"Aquilegia canadensis\")"
  end

  @impl true
  def execute(%{plant: plant}, frame) do
    case PlantSearch.get(plant) do
      {:ok, data} ->
        Reply.json(data, frame)

      {:error, :not_found} ->
        Reply.error("No plant found for \"#{plant}\". Try search_plants.", frame)
    end
  end
end
