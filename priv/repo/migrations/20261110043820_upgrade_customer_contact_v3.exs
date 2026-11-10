defmodule ShelleyPlants.Repo.Migrations.UpgradeCustomerContactV3 do
  use Ecto.Migration

  # CustomerContact v0.1.10: adds cc_images (admin-uploaded images served
  # from /cc/i/:id/:filename). Earlier versions are skipped.
  def up, do: CustomerContact.Migrations.up(version: 3)
  def down, do: CustomerContact.Migrations.down(version: 3)
end
