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

  describe "recommend/1 fit scoring and sort order" do
    test "a plant matching both sun and moisture is a great fit, sorted first" do
      plant_fixture(%{
        common_name: "Great Fit Plant",
        latin_name: "Greatus fitus",
        sun_level: "full_sun",
        moisture_level: "wet"
      })

      plant_fixture(%{
        common_name: "Fallback Plant",
        latin_name: "Fallbackus plantus",
        sun_level: "part_shade",
        moisture_level: "dry"
      })

      {plants, _alternates} =
        GardenDesign.recommend(%{
          "width" => "4",
          "length" => "6",
          "sun" => "full_sun",
          "moisture" => "wet"
        })

      great = Enum.find(plants, &(&1.common_name == "Great Fit Plant"))
      fallback = Enum.find(plants, &(&1.common_name == "Fallback Plant"))

      assert great.fit == :great
      assert fallback.fit == :fallback

      great_index = Enum.find_index(plants, &(&1.common_name == "Great Fit Plant"))
      fallback_index = Enum.find_index(plants, &(&1.common_name == "Fallback Plant"))
      assert great_index < fallback_index
    end

    test "a plant matching only sun (not moisture) is a good fit" do
      plant_fixture(%{
        common_name: "Sun Only Match",
        latin_name: "Sunonlyus matchus",
        sun_level: "full_sun",
        moisture_level: "dry"
      })

      {plants, _alternates} =
        GardenDesign.recommend(%{
          "width" => "4",
          "length" => "6",
          "sun" => "full_sun",
          "moisture" => "wet"
        })

      plant = Enum.find(plants, &(&1.common_name == "Sun Only Match"))
      assert plant.fit == :good
    end

    test "fit is great for sun match alone when no moisture was requested" do
      plant_fixture(%{
        common_name: "No Moisture Requested",
        latin_name: "Nomoisturus requestus",
        sun_level: "full_sun",
        moisture_level: "dry"
      })

      {plants, _alternates} =
        GardenDesign.recommend(%{"width" => "4", "length" => "6", "sun" => "full_sun"})

      plant = Enum.find(plants, &(&1.common_name == "No Moisture Requested"))
      assert plant.fit == :great
    end

    test "each plant's :color matches its :fit level", %{} do
      plant_fixture(%{
        common_name: "Colour Check Plant",
        latin_name: "Colourus checkus",
        sun_level: "full_sun",
        moisture_level: "wet"
      })

      {plants, _alternates} =
        GardenDesign.recommend(%{
          "width" => "4",
          "length" => "6",
          "sun" => "full_sun",
          "moisture" => "wet"
        })

      plant = Enum.find(plants, &(&1.common_name == "Colour Check Plant"))
      assert plant.color == Map.fetch!(GardenDesign.fit_colors(), plant.fit)
    end
  end
end
