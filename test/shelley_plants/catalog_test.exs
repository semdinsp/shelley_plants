defmodule ShelleyPlants.CatalogTest do
  use ShelleyPlants.DataCase

  alias ShelleyPlants.Catalog
  alias ShelleyPlants.Catalog.Plant

  import ShelleyPlants.AccountsFixtures
  import ShelleyPlants.CatalogFixtures

  @valid_attrs %{
    common_name: "Wild Bergamot",
    latin_name: "Monarda fistulosa",
    flower_color: "Lavender",
    bloom_time: "July-August",
    height: "60-120cm",
    chelsea_chop: false,
    light_requirements: "Full sun",
    moisture: "Average to dry",
    plant_type: "perennial",
    native_ontario: true,
    locally_native: true,
    ecological_benefit: "Attracts bees and hummingbirds",
    deer_resistant: true,
    notes: "Very fragrant",
    picture: nil
  }

  @update_attrs %{
    common_name: "Updated Wild Bergamot",
    plant_type: "annual",
    height: "30-60cm"
  }

  @invalid_attrs %{
    common_name: nil,
    latin_name: nil,
    plant_type: "shrub"
  }

  describe "list_plants/0" do
    test "returns all plants ordered by common name" do
      plant = plant_fixture(%{common_name: "Zigzag Goldenrod"})
      plant2 = plant_fixture(%{common_name: "Aster", latin_name: "Symphyotrichum cordifolium"})
      assert Catalog.list_plants() == [plant2, plant]
    end

    test "returns empty list when no plants exist" do
      assert Catalog.list_plants() == []
    end
  end

  describe "get_plant!/1" do
    test "returns the plant with given id" do
      plant = plant_fixture()
      assert Catalog.get_plant!(plant.id) == plant
    end

    test "raises for unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        Catalog.get_plant!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_plant/2" do
    test "with valid data creates a plant" do
      scope = admin_scope_fixture()
      assert {:ok, %Plant{} = plant} = Catalog.create_plant(scope, @valid_attrs)
      assert plant.common_name == "Wild Bergamot"
      assert plant.latin_name == "Monarda fistulosa"
      assert plant.plant_type == "perennial"
      assert plant.native_ontario == true
      assert plant.deer_resistant == true
    end

    test "with invalid plant_type returns error changeset" do
      scope = admin_scope_fixture()
      assert {:error, changeset} = Catalog.create_plant(scope, @invalid_attrs)
      assert %{plant_type: ["must be perennial or annual"]} = errors_on(changeset)
    end

    test "with missing required fields returns error changeset" do
      scope = admin_scope_fixture()
      assert {:error, changeset} = Catalog.create_plant(scope, %{})
      assert %{common_name: ["can't be blank"]} = errors_on(changeset)
      assert %{latin_name: ["can't be blank"]} = errors_on(changeset)
    end

    test "raises FunctionClauseError when scope is not admin" do
      non_admin_scope = user_scope_fixture()

      assert_raise FunctionClauseError, fn ->
        Catalog.create_plant(non_admin_scope, @valid_attrs)
      end
    end
  end

  describe "update_plant/3" do
    test "with valid data updates the plant" do
      scope = admin_scope_fixture()
      plant = plant_fixture()
      assert {:ok, %Plant{} = updated} = Catalog.update_plant(scope, plant, @update_attrs)
      assert updated.common_name == "Updated Wild Bergamot"
      assert updated.plant_type == "annual"
      assert updated.height == "30-60cm"
    end

    test "with invalid plant_type returns error changeset" do
      scope = admin_scope_fixture()
      plant = plant_fixture()
      assert {:error, changeset} = Catalog.update_plant(scope, plant, %{plant_type: "shrub"})
      assert %{plant_type: ["must be perennial or annual"]} = errors_on(changeset)
    end

    test "raises FunctionClauseError when scope is not admin" do
      non_admin_scope = user_scope_fixture()
      plant = plant_fixture()

      assert_raise FunctionClauseError, fn ->
        Catalog.update_plant(non_admin_scope, plant, @update_attrs)
      end
    end
  end

  describe "delete_plant/2" do
    test "deletes the plant" do
      scope = admin_scope_fixture()
      plant = plant_fixture()
      assert {:ok, %Plant{}} = Catalog.delete_plant(scope, plant)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_plant!(plant.id) end
    end

    test "raises FunctionClauseError when scope is not admin" do
      non_admin_scope = user_scope_fixture()
      plant = plant_fixture()

      assert_raise FunctionClauseError, fn ->
        Catalog.delete_plant(non_admin_scope, plant)
      end
    end
  end

  describe "change_plant/2" do
    test "returns a plant changeset" do
      plant = plant_fixture()
      assert %Ecto.Changeset{} = Catalog.change_plant(plant)
    end

    test "validates plant_type inclusion" do
      plant = plant_fixture()
      changeset = Catalog.change_plant(plant, %{plant_type: "shrub"})
      assert %{plant_type: ["must be perennial or annual"]} = errors_on(changeset)
    end
  end
end
