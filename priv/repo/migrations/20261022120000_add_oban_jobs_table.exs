defmodule ShelleyPlants.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up, do: Oban.Migrations.up()

  # Version 1 is Oban's first migration, so this drops everything.
  def down, do: Oban.Migrations.down(version: 1)
end
