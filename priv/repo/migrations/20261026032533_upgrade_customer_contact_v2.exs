defmodule ShelleyPlants.Repo.Migrations.UpgradeCustomerContactV2 do
  use Ecto.Migration

  # CustomerContact v0.1.7: adds cc_contacts (people added by hand on the
  # Audience page). Version 1 tables already exist and are skipped.
  def up, do: CustomerContact.Migrations.up(version: 2)
  def down, do: CustomerContact.Migrations.down(version: 2)
end
