defmodule ShelleyPlants.MCP.Public.Server do
  @moduledoc """
  Public, read-only MCP server for AI agents, mounted at `/mcp/public` with no
  authentication (rate limited per IP).

  Strictly separate from the admin server (`ShelleyPlants.MCP.PlantsServer`
  at `/mcp`): only the read-only tools below are registered, and they go
  through `ShelleyPlants.PlantSearch`, which exposes only what the public
  plant pages show.
  """

  use Anubis.Server,
    name: "biosphere-native-plants",
    version: "1.0.0",
    capabilities: [:tools]

  component(ShelleyPlants.MCP.Public.SearchPlants)
  component(ShelleyPlants.MCP.Public.GetPlant)
  component(ShelleyPlants.MCP.Public.ListFilters)
  component(ShelleyPlants.MCP.Public.RecommendPlants)

  @impl true
  def init(_client_info, frame), do: {:ok, frame}
end
