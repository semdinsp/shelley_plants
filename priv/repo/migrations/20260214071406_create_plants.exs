defmodule ShelleyPlants.Repo.Migrations.CreatePlants do
  use Ecto.Migration

  def change do
    create table(:plants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :common_name, :string, null: false
      add :latin_name, :string, null: false
      add :flower_color, :string, null: false
      add :bloom_time, :string, null: false
      add :height, :string, null: false
      add :chelsea_chop, :boolean, default: false, null: false
      add :light_requirements, :string, null: false
      add :moisture, :string, null: false
      add :plant_type, :string, null: false
      add :native_ontario, :boolean, default: false, null: false
      add :locally_native, :boolean, default: false, null: false
      add :ecological_benefit, :text
      add :deer_resistant, :boolean, default: false, null: false
      add :notes, :text
      add :picture, :string

      timestamps(type: :utc_datetime)
    end
  end
end
