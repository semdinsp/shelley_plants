defmodule ShelleyPlantsWeb.PlantSlugTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import ShelleyPlants.CatalogFixtures

  alias ShelleyPlants.Catalog.Plant

  describe "Plant.slugify/1" do
    test "builds lowercase hyphenated slugs from the Latin name" do
      assert Plant.slugify("Aquilegia canadensis") == "aquilegia-canadensis"

      assert Plant.slugify("Prunella vulgaris var. lanceolata") ==
               "prunella-vulgaris-var-lanceolata"

      assert Plant.slugify("Symphyotrichum novae-angliae") == "symphyotrichum-novae-angliae"
    end

    test "ignores anything in brackets" do
      assert Plant.slugify("Oligoneuron album (formerly Solidago ptarmicoides)") ==
               "oligoneuron-album"
    end
  end

  test "a new plant gets a slug, and plant URLs use it", %{conn: conn} do
    plant = plant_fixture(%{latin_name: "Aquilegia canadensis", common_name: "Canada Columbine"})

    assert plant.slug == "aquilegia-canadensis"
    assert ~p"/plants/#{plant}" == "/plants/aquilegia-canadensis"

    assert conn |> get(~p"/plants/aquilegia-canadensis") |> html_response(200) =~
             "Canada Columbine"
  end

  describe "old UUID URLs" do
    setup do
      %{plant: plant_fixture(%{latin_name: "Aquilegia canadensis"})}
    end

    test "301-redirect to the slug URL", %{conn: conn, plant: plant} do
      conn = get(conn, "/plants/#{plant.id}")

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["/plants/aquilegia-canadensis"]
    end

    test "keep the query string and the edit path", %{conn: conn, plant: plant} do
      conn = get(conn, "/plants/#{plant.id}/edit?return_to=show")

      assert conn.status == 301

      assert get_resp_header(conn, "location") == [
               "/plants/aquilegia-canadensis/edit?return_to=show"
             ]
    end

    test "an unknown UUID is a 404, not a redirect", %{conn: conn} do
      assert_error_sent 404, fn -> get(conn, "/plants/#{Ecto.UUID.generate()}") end
    end
  end
end
