defmodule ShelleyPlants.Repo.Migrations.AddStructuredFieldsToPlants do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :height_min_cm, :integer
      add :height_max_cm, :integer
      add :spread_cm, :integer
      add :sun_level, :string
      add :moisture_level, :string
    end

    create index(:plants, [:sun_level])
    create index(:plants, [:moisture_level])
  end
end
