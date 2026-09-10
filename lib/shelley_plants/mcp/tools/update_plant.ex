defmodule ShelleyPlants.MCP.Tools.UpdatePlant do
  @moduledoc "Update fields on an existing plant in the native plant catalog. Requires an admin token."

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.Catalog
  alias ShelleyPlants.MCP.Tools.Support

  schema do
    field :id, :string, required: true, description: "The plant's id"
    field :common_name, :string
    field :latin_name, :string
    field :flower_color, :string
    field :bloom_time, :string
    field :height, :string
    field :chelsea_chop, :boolean
    field :light_requirements, :string
    field :moisture, :string
    field :plant_type, :enum, values: ["perennial", "annual"]
    field :native_ontario, :boolean
    field :locally_native, :boolean
    field :deer_resistant, :boolean
    field :ecological_benefit, :string
    field :notes, :string
    field :category, :enum, values: ["Wildflower", "Grass", "Shrub", "Tree"]
    field :height_min_cm, :integer
    field :height_max_cm, :integer
    field :spread_cm, :integer
    field :sun_level, :enum, values: ["full_sun", "part_shade", "full_shade"]
    field :moisture_level, :enum, values: ["dry", "average", "moist", "wet"]

    field :moisture_unacceptable, {:list, {:enum, ["dry", "average", "moist", "wet"]}},
      description: "Moisture levels this plant cannot tolerate"
  end

  @impl true
  def execute(%{id: id} = params, frame) do
    attrs = Map.delete(params, :id)

    with :ok <- Support.require_scope(frame, "write"),
         {:ok, scope} <- Support.require_admin_scope(frame),
         {:ok, plant} <- fetch_plant(id),
         {:ok, plant} <- Catalog.update_plant(scope, plant, attrs) do
      Support.json_reply(Support.plant_json(plant), frame)
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
