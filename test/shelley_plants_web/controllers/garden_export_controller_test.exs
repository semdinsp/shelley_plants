defmodule ShelleyPlantsWeb.GardenExportControllerTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import ShelleyPlants.CatalogFixtures

  describe "GET /design-garden/export" do
    test "returns a CSV file", %{conn: conn} do
      conn = get(conn, ~p"/design-garden/export", %{"sun" => "full_sun"})

      assert response_content_type(conn, :csv)
      assert get_resp_header(conn, "content-disposition") |> hd() =~ "attachment"
      assert get_resp_header(conn, "content-disposition") |> hd() =~ "garden_plant_list_"
      assert get_resp_header(conn, "content-disposition") |> hd() =~ ".csv"
    end

    test "CSV contains the header row and matched plants", %{conn: conn} do
      plant_fixture(%{
        common_name: "Black-eyed Susan",
        latin_name: "Rudbeckia hirta",
        category: "Wildflower",
        sun_level: "full_sun",
        height_min_cm: 30,
        height_max_cm: 90,
        spread_cm: 45
      })

      conn =
        get(conn, ~p"/design-garden/export", %{
          "sun" => "full_sun",
          "width" => "3",
          "length" => "3"
        })

      body = response(conn, 200)
      lines = String.split(body, "\r\n", trim: true)

      assert hd(lines) == "Common Name,Latin Name,Category,Quantity,Height (cm),Sun"
      assert Enum.any?(lines, &String.contains?(&1, "Black-eyed Susan"))
      assert Enum.any?(lines, &String.contains?(&1, "Rudbeckia hirta"))
      assert Enum.any?(lines, &String.contains?(&1, "Full sun"))
    end

    test "quotes fields containing commas", %{conn: conn} do
      plant_fixture(%{
        common_name: "Aster, New England",
        latin_name: "Symphyotrichum novae-angliae",
        sun_level: "full_sun",
        height_min_cm: 60,
        height_max_cm: 120
      })

      conn = get(conn, ~p"/design-garden/export", %{"sun" => "full_sun"})

      body = response(conn, 200)
      assert body =~ ~s("Aster, New England")
    end
  end
end
