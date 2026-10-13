defmodule ShelleyPlants.MCP.Public.ListFilters do
  @moduledoc """
  List the valid values for each search_plants filter (categories, light,
  moisture, bloom seasons, wildlife goals, flower colours, height range) for
  the Ontario native plants sold by Biosphere Native Plants. Call this before
  search_plants or recommend_plants to build a valid query.
  """

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.MCP.Public.Reply
  alias ShelleyPlants.PlantSearch

  schema do
  end

  @impl true
  def execute(_params, frame), do: Reply.json(PlantSearch.filters(), frame)
end
