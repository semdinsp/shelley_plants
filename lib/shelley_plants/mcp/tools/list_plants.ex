defmodule ShelleyPlants.MCP.Tools.ListPlants do
  @moduledoc "List all plants in the native plant catalog, optionally filtered by category."

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.Catalog
  alias ShelleyPlants.MCP.Tools.Support

  schema do
    field :category, :string,
      description: "Optional category filter: Wildflower, Grass, Shrub, or Tree"
  end

  @impl true
  def execute(params, frame) do
    case Support.require_scope(frame, "read") do
      :ok ->
        plants =
          params
          |> Map.get(:category)
          |> Catalog.list_plants_by_category()
          |> Enum.map(&Support.plant_json/1)

        Support.json_reply(plants, frame)

      {:error, message} ->
        Support.error_reply(message, frame)
    end
  end
end
