defmodule ShelleyPlantsWeb.Admin.PlantExportControllerTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import ShelleyPlants.AccountsFixtures
  import ShelleyPlants.CatalogFixtures

  defp admin_conn(conn) do
    user = user_fixture()
    {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user, true)
    log_in_user(conn, admin)
  end

  describe "GET /admin/plants/export" do
    test "redirects guests to log-in", %{conn: conn} do
      conn = get(conn, ~p"/admin/plants/export")
      assert redirected_to(conn) =~ "/users/log-in"
    end

    test "redirects non-admin users to home", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      conn = get(conn, ~p"/admin/plants/export")
      assert redirected_to(conn) == ~p"/"
    end

    test "returns JSON file for admin users", %{conn: conn} do
      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/plants/export")

      assert response_content_type(conn, :json)
      assert get_resp_header(conn, "content-disposition") |> hd() =~ "attachment"
      assert get_resp_header(conn, "content-disposition") |> hd() =~ "plants_"
      assert get_resp_header(conn, "content-disposition") |> hd() =~ ".json"
    end

    test "export contains all expected fields", %{conn: conn} do
      plant_fixture(%{
        latin_name: "Rudbeckia hirta",
        common_name: "Black-eyed Susan",
        plant_type: "perennial",
        flower_color: "golden yellow",
        bloom_time: "July–September",
        height: "30–90 cm",
        light_requirements: "Full sun",
        moisture: "Dry to medium",
        chelsea_chop: false,
        native_ontario: true,
        locally_native: true,
        deer_resistant: false,
        ecological_benefit: "Attracts bees and butterflies",
        notes: "Great for cut flowers",
        picture: "/images/plants/rudbeckia.jpg"
      })

      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/plants/export")

      body = json_response(conn, 200)
      assert is_list(body)

      plant = Enum.find(body, &(&1["latin_name"] == "Rudbeckia hirta"))
      assert plant["common_name"] == "Black-eyed Susan"
      assert plant["plant_type"] == "perennial"
      assert plant["flower_color"] == "golden yellow"
      assert plant["bloom_time"] == "July–September"
      assert plant["height"] == "30–90 cm"
      assert plant["light_requirements"] == "Full sun"
      assert plant["moisture"] == "Dry to medium"
      assert plant["chelsea_chop"] == false
      assert plant["native_ontario"] == true
      assert plant["locally_native"] == true
      assert plant["deer_resistant"] == false
      assert plant["ecological_benefit"] == "Attracts bees and butterflies"
      assert plant["notes"] == "Great for cut flowers"
      assert plant["picture"] == "/images/plants/rudbeckia.jpg"
    end

    test "export includes null for optional fields when absent", %{conn: conn} do
      plant_fixture(%{
        latin_name: "Solidago canadensis unique",
        common_name: "Canada Goldenrod",
        ecological_benefit: nil,
        notes: nil,
        picture: nil
      })

      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/plants/export")

      body = json_response(conn, 200)
      plant = Enum.find(body, &(&1["latin_name"] == "Solidago canadensis unique"))
      assert Map.has_key?(plant, "ecological_benefit")
      assert Map.has_key?(plant, "notes")
      assert Map.has_key?(plant, "picture")
      assert plant["ecological_benefit"] == nil
      assert plant["notes"] == nil
      assert plant["picture"] == nil
    end

    test "export is ordered by common name", %{conn: conn} do
      plant_fixture(%{latin_name: "Zzz plantus", common_name: "Zigzag Goldenrod"})
      plant_fixture(%{latin_name: "Aaa plantus", common_name: "Aromatic Aster"})

      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/plants/export")

      body = json_response(conn, 200)
      names = Enum.map(body, & &1["common_name"])
      assert names == Enum.sort(names)
    end

    test "export is compatible with import format (all required keys present)", %{conn: conn} do
      plant_fixture()

      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/plants/export")

      body = json_response(conn, 200)
      required_keys = ~w(common_name latin_name plant_type flower_color bloom_time
                         height light_requirements moisture chelsea_chop native_ontario
                         locally_native deer_resistant)

      for plant <- body do
        for key <- required_keys do
          assert Map.has_key?(plant, key), "Missing key #{key} in export"
        end
      end
    end
  end
end
