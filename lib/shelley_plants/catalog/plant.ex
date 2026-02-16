defmodule ShelleyPlants.Catalog.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  @plant_types ~w(perennial annual)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "plants" do
    field :common_name, :string
    field :latin_name, :string
    field :flower_color, :string
    field :bloom_time, :string
    field :height, :string
    field :chelsea_chop, :boolean, default: false
    field :light_requirements, :string
    field :moisture, :string
    field :plant_type, :string
    field :native_ontario, :boolean, default: false
    field :locally_native, :boolean, default: false
    field :ecological_benefit, :string
    field :deer_resistant, :boolean, default: false
    field :notes, :string
    field :picture, :string

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(common_name latin_name flower_color bloom_time height chelsea_chop
                      light_requirements moisture plant_type native_ontario locally_native
                      deer_resistant)a
  @optional_fields ~w(ecological_benefit notes picture)a

  @doc false
  def changeset(plant, attrs) do
    plant
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:plant_type, @plant_types, message: "must be perennial or annual")
    |> unique_constraint(:latin_name)
  end
end
