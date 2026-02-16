defmodule ShelleyPlants.Repo.Migrations.AddUniqueIndexToPlantsLatinName do
  use Ecto.Migration

  def change do
    create unique_index(:plants, [:latin_name])
  end
end
