defmodule ShelleyPlants.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ShelleyPlants.Catalog` context.
  """

  alias ShelleyPlants.AccountsFixtures

  @doc """
  Returns an admin scope for use in catalog fixture creation.
  """
  def admin_scope_fixture do
    user = AccountsFixtures.user_fixture()
    {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
    ShelleyPlants.Accounts.Scope.for_user(admin_user)
  end

  @doc """
  Generate a plant. Requires an admin scope for creation.
  """
  def plant_fixture(attrs \\ %{}) do
    scope = admin_scope_fixture()

    attrs =
      Enum.into(attrs, %{
        bloom_time: "June-August",
        chelsea_chop: false,
        common_name: "Purple Coneflower",
        deer_resistant: true,
        ecological_benefit: "Attracts pollinators",
        flower_color: "Purple",
        height: "60-90cm",
        latin_name: "Echinacea purpurea",
        light_requirements: "Full sun to part shade",
        locally_native: true,
        moisture: "Average to dry",
        native_ontario: true,
        notes: "Easy to grow",
        picture: nil,
        plant_type: "perennial"
      })

    {:ok, plant} = ShelleyPlants.Catalog.create_plant(scope, attrs)
    plant
  end
end
