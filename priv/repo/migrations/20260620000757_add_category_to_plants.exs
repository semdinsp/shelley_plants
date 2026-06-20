defmodule ShelleyPlants.Repo.Migrations.AddCategoryToPlants do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :category, :string
    end
  end
end
