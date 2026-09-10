defmodule ShelleyPlants.Repo.Migrations.AddMoistureUnacceptableToPlants do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :moisture_unacceptable, {:array, :string}, null: false, default: []
    end
  end
end
