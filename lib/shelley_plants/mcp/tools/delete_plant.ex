defmodule ShelleyPlants.MCP.Tools.DeletePlant do
  @moduledoc "Delete a plant from the native plant catalog. Requires an admin token."

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.Catalog
  alias ShelleyPlants.MCP.Tools.Support

  schema do
    field :id, :string, required: true, description: "The plant's id"
  end

  @impl true
  def execute(%{id: id}, frame) do
    with :ok <- Support.require_scope(frame, "write"),
         {:ok, scope} <- Support.require_admin_scope(frame),
         {:ok, plant} <- fetch_plant(id),
         {:ok, plant} <- Catalog.delete_plant(scope, plant) do
      Support.json_reply(%{deleted: true, id: plant.id}, frame)
    else
      {:error, %Ecto.Changeset{} = changeset} -> Support.changeset_error_reply(changeset, frame)
      {:error, message} -> Support.error_reply(message, frame)
    end
  end

  defp fetch_plant(id) do
    {:ok, Catalog.get_plant!(id)}
  rescue
    Ecto.NoResultsError -> {:error, "No plant found with id #{id}."}
    Ecto.Query.CastError -> {:error, "#{id} is not a valid plant id."}
  end
end
