defmodule ShelleyPlants.MCP.Tools.CreatePlant do
  @moduledoc "Create a new plant in the native plant catalog. Requires an admin token."

  use Anubis.Server.Component, type: :tool

  alias ShelleyPlants.Catalog
  alias ShelleyPlants.MCP.Tools.Support

  schema do
    field :common_name, :string, required: true
    field :latin_name, :string, required: true
    field :flower_color, :string, required: true
    field :bloom_time, :string, required: true
    field :height, :string, required: true
    field :chelsea_chop, :boolean, required: true
    field :light_requirements, :string, required: true
    field :moisture, :string, required: true
    field :plant_type, :enum, required: true, values: ["perennial", "annual"]
    field :native_ontario, :boolean, required: true
    field :locally_native, :boolean, required: true
    field :deer_resistant, :boolean, required: true
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
  def execute(params, frame) do
    with :ok <- Support.require_scope(frame, "write"),
         {:ok, scope} <- Support.require_admin_scope(frame),
         {:ok, plant} <- Catalog.create_plant(scope, params) do
      Support.json_reply(Support.plant_json(plant), frame)
    else
      {:error, %Ecto.Changeset{} = changeset} -> Support.changeset_error_reply(changeset, frame)
      {:error, message} -> Support.error_reply(message, frame)
    end
  end
end
