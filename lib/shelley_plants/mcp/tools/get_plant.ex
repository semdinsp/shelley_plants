defmodule ShelleyPlants.MCP.Tools.GetPlant do
  @moduledoc "Get a single plant from the native plant catalog by its id."

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.Catalog
  alias ShelleyPlants.MCP.Tools.Support

  schema do
    field :id, :string, required: true, description: "The plant's id"
  end

  @impl true
  def execute(%{id: id}, frame) do
    case Support.require_scope(frame, "read") do
      :ok ->
        try do
          Support.json_reply(Support.plant_json(Catalog.get_plant!(id)), frame)
        rescue
          Ecto.NoResultsError -> Support.error_reply("No plant found with id #{id}.", frame)
          Ecto.Query.CastError -> Support.error_reply("#{id} is not a valid plant id.", frame)
        end

      {:error, message} ->
        Support.error_reply(message, frame)
    end
  end
end
