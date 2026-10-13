defmodule ShelleyPlantsWeb.PublicMcpTest do
  # Shared sandbox: tool calls run in a session process spawned by the
  # Anubis server supervisor, not the test process (as in McpTest).
  use ShelleyPlantsWeb.ConnCase, async: false

  import ShelleyPlants.CatalogFixtures

  alias ShelleyPlantsWeb.Endpoint

  # Fields the public plant pages show. Nothing else may be returned.
  @public_fields ~w(common_name latin_name category light moisture height bloom_time
                    flower_color native_status deer_resistant url slug plant_type
                    light_requirements moisture_notes height_min_cm height_max_cm spread_cm
                    native_to_ontario locally_native near_native chelsea_chop
                    ecological_benefit notes image_url fit)

  setup do
    columbine =
      plant_fixture(%{
        common_name: "Canada Columbine",
        latin_name: "Aquilegia canadensis",
        category: "Wildflower",
        sun_level: "part_shade",
        moisture_level: "average",
        moisture_unacceptable: ["wet"],
        height_min_cm: 30,
        height_max_cm: 60,
        bloom_time: "Late spring to early summer",
        flower_color: "Red and yellow",
        ecological_benefit: "Early nectar for hummingbirds and bees.",
        deer_resistant: true
      })

    grass =
      plant_fixture(%{
        common_name: "Big Bluestem",
        latin_name: "Andropogon gerardii",
        category: "Grass",
        sun_level: "full_sun",
        moisture_level: "dry",
        height_min_cm: 120,
        height_max_cm: 240,
        bloom_time: "Late summer to fall",
        flower_color: "Purplish-bronze",
        ecological_benefit: "Host plant for skipper caterpillars.",
        deer_resistant: false
      })

    %{columbine: columbine, grass: grass}
  end

  defp mcp_conn(conn) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json")
  end

  defp initialize(path \\ "/mcp/public") do
    conn =
      build_conn()
      |> mcp_conn()
      |> post(path, %{
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2025-06-18",
          "capabilities" => %{},
          "clientInfo" => %{"name" => "test", "version" => "1.0"}
        }
      })

    {conn, conn |> get_resp_header("mcp-session-id") |> List.first()}
  end

  defp rpc(session_id, method, params) do
    build_conn()
    |> mcp_conn()
    |> put_req_header("mcp-session-id", session_id)
    |> post("/mcp/public", %{
      "jsonrpc" => "2.0",
      "id" => 2,
      "method" => method,
      "params" => params
    })
    |> json_response(200)
  end

  defp call_tool(session_id, name, arguments) do
    body = rpc(session_id, "tools/call", %{"name" => name, "arguments" => arguments})
    result = body["result"]
    {result["isError"] == true, result |> get_in(["content", Access.at(0), "text"])}
  end

  defp call_json(session_id, name, arguments) do
    {false, text} = call_tool(session_id, name, arguments)
    Jason.decode!(text)
  end

  defp assert_public_fields(plant) do
    extra = Map.keys(plant) -- @public_fields
    assert extra == [], "non-public fields returned: #{inspect(extra)}"
    refute Map.has_key?(plant, "id")
    refute Map.has_key?(plant, "moisture_unacceptable")
  end

  test "initialize works with no authentication" do
    {conn, session_id} = initialize()
    assert conn.status == 200
    assert is_binary(session_id)
  end

  test "lists only the four public read-only tools" do
    {_conn, session_id} = initialize()
    tools = rpc(session_id, "tools/list", %{}) |> get_in(["result", "tools"])

    assert tools |> Enum.map(& &1["name"]) |> Enum.sort() ==
             ~w(get_plant list_filters recommend_plants search_plants)

    for tool <- tools, do: assert(tool["description"] =~ "Ontario native")
  end

  test "admin tools can't be reached through the public endpoint", %{columbine: columbine} do
    {_conn, session_id} = initialize()

    for {name, args} <- [
          {"create_plant", %{"common_name" => "X"}},
          {"update_plant", %{"id" => columbine.id, "common_name" => "Hacked"}},
          {"delete_plant", %{"id" => columbine.id}},
          {"list_plants", %{}}
        ] do
      body = rpc(session_id, "tools/call", %{"name" => name, "arguments" => args})
      assert body["error"] || get_in(body, ["result", "isError"]), "#{name} should fail"
    end

    assert ShelleyPlants.Repo.get!(ShelleyPlants.Catalog.Plant, columbine.id).common_name ==
             "Canada Columbine"
  end

  test "the admin endpoint still requires a token" do
    {conn, _session_id} = initialize("/mcp")
    assert conn.status == 401
  end

  describe "search_plants" do
    test "filters and returns compact public results with absolute URLs" do
      {_conn, session_id} = initialize()

      result =
        call_json(session_id, "search_plants", %{
          "light" => "part_shade",
          "wildlife" => "hummingbirds",
          "bloom_season" => "spring",
          "deer_resistant" => true
        })

      assert result["total"] == 1
      assert [plant] = result["plants"]
      assert plant["common_name"] == "Canada Columbine"
      assert plant["url"] == Endpoint.url() <> "/plants/aquilegia-canadensis"
      assert_public_fields(plant)
    end

    test "supports text, category, height and colour filters" do
      {_conn, session_id} = initialize()

      names = fn args ->
        session_id
        |> call_json("search_plants", args)
        |> Map.fetch!("plants")
        |> Enum.map(& &1["common_name"])
      end

      assert names.(%{"query" => "andropogon"}) == ["Big Bluestem"]
      assert names.(%{"category" => "Grass"}) == ["Big Bluestem"]
      assert names.(%{"max_height_cm" => 100}) == ["Canada Columbine"]
      assert names.(%{"min_height_cm" => 200}) == ["Big Bluestem"]
      assert names.(%{"flower_color" => "bronze"}) == ["Big Bluestem"]
      assert names.(%{"bloom_season" => "fall"}) == ["Big Bluestem"]
      assert names.(%{"wildlife" => "host_plant"}) == ["Big Bluestem"]
    end

    test "caps results at 25" do
      for i <- 1..30,
          do: plant_fixture(%{latin_name: "Testus plantus#{i}", common_name: "Test #{i}"})

      {_conn, session_id} = initialize()

      result = call_json(session_id, "search_plants", %{"limit" => 100})
      assert length(result["plants"]) == 25
      assert result["total"] == 32
    end
  end

  describe "get_plant" do
    test "finds a plant by slug or Latin name and returns only public fields" do
      {_conn, session_id} = initialize()

      by_slug = call_json(session_id, "get_plant", %{"plant" => "aquilegia-canadensis"})
      by_latin = call_json(session_id, "get_plant", %{"plant" => "aquilegia CANADENSIS"})

      assert by_slug == by_latin
      assert by_slug["common_name"] == "Canada Columbine"
      assert by_slug["ecological_benefit"] =~ "hummingbirds"
      assert by_slug["url"] == Endpoint.url() <> "/plants/aquilegia-canadensis"
      assert_public_fields(by_slug)
    end

    test "reports an unknown plant as an error" do
      {_conn, session_id} = initialize()
      assert {true, text} = call_tool(session_id, "get_plant", %{"plant" => "nonexistent"})
      assert text =~ "No plant found"
    end
  end

  test "list_filters returns the valid filter values" do
    {_conn, session_id} = initialize()
    filters = call_json(session_id, "list_filters", %{})

    assert filters["category"] == ~w(Wildflower Grass Shrub Tree)
    assert filters["light"] == ~w(full_sun part_shade full_shade)
    assert "hummingbirds" in filters["wildlife"]
    assert "yellow" in filters["flower_color"]
    assert filters["height_cm"] == %{"min" => 60, "max" => 240}
    assert filters["max_results"] == 25
  end

  test "recommend_plants uses the garden planner and returns a fit for each plant" do
    {_conn, session_id} = initialize()

    result =
      call_json(session_id, "recommend_plants", %{"light" => "full_sun", "moisture" => "dry"})

    assert [%{"common_name" => "Big Bluestem", "fit" => "great"} = plant | _] = result["plants"]
    assert_public_fields(plant)
  end

  test "invalid filter values get a helpful error" do
    {_conn, session_id} = initialize()

    # Anubis validates enum values against the tool schema before the tool runs
    body =
      rpc(session_id, "tools/call", %{
        "name" => "recommend_plants",
        "arguments" => %{"light" => "moonlight"}
      })

    assert body["error"]["data"]["message"] =~ ~s(light: expected one of ["full_sun")

    # Values the schema can't check (e.g. a negative height) get a tool error
    assert {true, text} = call_tool(session_id, "search_plants", %{"max_height_cm" => -5})
    assert text =~ "positive whole number"
  end
end
