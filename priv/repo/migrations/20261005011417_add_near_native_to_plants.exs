defmodule ShelleyPlants.Repo.Migrations.AddNearNativeToPlants do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :near_native, :boolean, default: false, null: false
    end
  end
end
