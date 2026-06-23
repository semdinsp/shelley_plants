defmodule ShelleyPlants.Catalog.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  @plant_types ~w(perennial annual)
  @categories ~w(Wildflower Grass Shrub Tree)
  @sun_levels ~w(full_sun part_shade full_shade)
  @moisture_levels ~w(dry average moist wet)

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
    field :category, :string
    field :height_min_cm, :integer
    field :height_max_cm, :integer
    field :spread_cm, :integer
    field :sun_level, :string
    field :moisture_level, :string
    field :picture, :string

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(common_name latin_name flower_color bloom_time height chelsea_chop
                      light_requirements moisture plant_type native_ontario locally_native
                      deer_resistant)a
  @optional_fields ~w(ecological_benefit notes picture category
                      height_min_cm height_max_cm spread_cm sun_level moisture_level)a

  @doc false
  def changeset(plant, attrs) do
    plant
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:plant_type, @plant_types, message: "must be perennial or annual")
    |> nilify_blank(:category)
    |> nilify_blank(:sun_level)
    |> nilify_blank(:moisture_level)
    |> validate_inclusion(:category, @categories ++ [nil],
      message: "must be Wildflower, Grass, Shrub, or Tree"
    )
    |> validate_inclusion(:sun_level, @sun_levels ++ [nil],
      message: "must be full_sun, part_shade, or full_shade"
    )
    |> validate_inclusion(:moisture_level, @moisture_levels ++ [nil],
      message: "must be dry, average, moist, or wet"
    )
    |> validate_number(:height_min_cm, greater_than: 0, less_than: 2000)
    |> validate_number(:height_max_cm, greater_than: 0, less_than: 2000)
    |> validate_number(:spread_cm, greater_than: 0, less_than: 500)
    |> unique_constraint(:latin_name)
  end

  # Convert empty string submissions from select prompts to nil
  defp nilify_blank(changeset, field) do
    case get_change(changeset, field) do
      "" -> put_change(changeset, field, nil)
      _ -> changeset
    end
  end
end
