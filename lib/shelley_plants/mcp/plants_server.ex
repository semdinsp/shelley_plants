defmodule ShelleyPlants.MCP.PlantsServer do
  @moduledoc """
  MCP server exposing the native plant catalog to MCP clients.

  Mounted at `/mcp`, authenticated via `ShelleyPlantsWeb.Plugs.McpAuth` using
  the tokens users create on the settings page. Read tools require the
  "read" scope; write tools require "write" and an admin user, matching
  `ShelleyPlants.Catalog`'s own authorization rules.
  """

  use Anubis.Server,
    name: "shelley-plants",
    version: "1.0.0",
    capabilities: [:tools]

  component(ShelleyPlants.MCP.Tools.ListPlants)
  component(ShelleyPlants.MCP.Tools.GetPlant)
  component(ShelleyPlants.MCP.Tools.CreatePlant)
  component(ShelleyPlants.MCP.Tools.UpdatePlant)
  component(ShelleyPlants.MCP.Tools.DeletePlant)

  @impl true
  def init(_client_info, frame) do
    {:ok, frame}
  end
end
