defmodule ShelleyPlants.Repo.Migrations.AddCustomerContact do
  use Ecto.Migration

  # The cc_* tables for CustomerContact campaign email (campaigns, deliveries,
  # events, suppressions, test recipients, tags, taggings).
  def up, do: CustomerContact.Migrations.up(version: 1)
  def down, do: CustomerContact.Migrations.down(version: 1)
end
