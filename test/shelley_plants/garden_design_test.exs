defmodule ShelleyPlants.GardenDesignTest do
  use ShelleyPlants.DataCase

  import ShelleyPlants.CatalogFixtures

  alias ShelleyPlants.GardenDesign

  describe "recommend/1 moisture handling" do
    test "excludes plants that can't tolerate the garden's moisture" do
      plant_fixture(%{
        common_name: "Tolerates Wet",
        latin_name: "Toleratus wetus",
        sun_level: "full_sun",
        moisture_level: "average",
        moisture_unacceptable: [],
        height_min_cm: 30,
        height_max_cm: 60
      })

      plant_fixture(%{
        common_name: "Hates Wet",
        latin_name: "Hatus wetus",
        sun_level: "full_sun",
        moisture_level: "average",
        moisture_unacceptable: ["wet"],
        height_min_cm: 30,
        height_max_cm: 60
      })

      {plants, _alternates} =
        GardenDesign.recommend(%{
          "width" => "4",
          "length" => "6",
          "sun" => "full_sun",
          "moisture" => "wet"
        })

      names = Enum.map(plants, & &1.common_name)
      assert "Tolerates Wet" in names
      refute "Hates Wet" in names
    end

    test "does not exclude anything when no moisture is selected" do
      plant_fixture(%{
        common_name: "Hates Wet",
        latin_name: "Hatus wetus2",
        sun_level: "full_sun",
        moisture_unacceptable: ["wet"],
        height_min_cm: 30,
        height_max_cm: 60
      })

      {plants, _alternates} =
        GardenDesign.recommend(%{"width" => "4", "length" => "6", "sun" => "full_sun"})

      assert Enum.any?(plants, &(&1.common_name == "Hates Wet"))
    end

    test "prefers plants whose moisture_level matches, without excluding others" do
      plant_fixture(%{
        common_name: "Matches Wet",
        latin_name: "Matchus wetus",
        sun_level: "full_sun",
        moisture_level: "wet",
        height_min_cm: 90,
        height_max_cm: 120
      })

      plant_fixture(%{
        common_name: "Different Moisture",
        latin_name: "Differentus moisturus",
        sun_level: "full_sun",
        moisture_level: "dry",
        height_min_cm: 10,
        height_max_cm: 30
      })

      {plants, _alternates} =
        GardenDesign.recommend(%{
          "width" => "4",
          "length" => "6",
          "sun" => "full_sun",
          "moisture" => "wet"
        })

      names = Enum.map(plants, & &1.common_name)
      assert "Matches Wet" in names
      assert "Different Moisture" in names

      match_index = Enum.find_index(plants, &(&1.common_name == "Matches Wet"))
      other_index = Enum.find_index(plants, &(&1.common_name == "Different Moisture"))
      assert match_index < other_index
    end
  end
end
