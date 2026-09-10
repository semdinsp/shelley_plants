defmodule ShelleyPlantsWeb.McpTest do
  # Shared sandbox mode: MCP tool calls execute inside a session process
  # spawned by the Anubis server supervisor, not the test process, so the
  # DB connection must be shared rather than explicitly allowed.
  use ShelleyPlantsWeb.ConnCase, async: false

  import ShelleyPlants.AccountsFixtures
  import ShelleyPlants.CatalogFixtures

  alias ShelleyPlants.Accounts

  defp admin_token_fixture(scopes \\ ["read", "write"]) do
    user = user_fixture()
    {:ok, admin_user} = Accounts.set_user_admin(user, true)

    {:ok, raw_token, _mcp_token} =
      Accounts.create_mcp_token(admin_user, %{"name" => "t", "scopes" => scopes})

    {admin_user, raw_token}
  end

  defp mcp_conn(conn, token) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json")
  end

  defp initialize(conn, token) do
    conn = mcp_conn(conn, token)

    conn =
      post(conn, ~p"/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2025-06-18",
          "capabilities" => %{},
          "clientInfo" => %{"name" => "test", "version" => "1.0"}
        }
      })

    session_id = conn |> get_resp_header("mcp-session-id") |> List.first()
    {conn, session_id}
  end

  defp call_tool(_conn, token, session_id, name, arguments, id \\ 2) do
    build_conn()
    |> mcp_conn(token)
    |> put_req_header("mcp-session-id", session_id)
    |> post(~p"/mcp", %{
      "jsonrpc" => "2.0",
      "id" => id,
      "method" => "tools/call",
      "params" => %{"name" => name, "arguments" => arguments}
    })
  end

  describe "authentication" do
    test "rejects requests with no bearer token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept", "application/json")
        |> post(~p"/mcp", %{
          "jsonrpc" => "2.0",
          "id" => 1,
          "method" => "initialize",
          "params" => %{}
        })

      assert conn.status == 401
    end

    test "rejects requests with an invalid bearer token", %{conn: conn} do
      {conn, _session_id} = initialize(conn, "not-a-real-token")
      assert conn.status == 401
    end

    test "rejects requests with a revoked token", %{conn: conn} do
      {admin_user, raw_token} = admin_token_fixture()
      [mcp_token] = Accounts.list_mcp_tokens(admin_user)
      {:ok, _} = Accounts.revoke_mcp_token(admin_user, mcp_token)

      {conn, _session_id} = initialize(conn, raw_token)
      assert conn.status == 401
    end

    test "accepts requests with a valid token", %{conn: conn} do
      {_admin_user, raw_token} = admin_token_fixture()
      {conn, session_id} = initialize(conn, raw_token)

      assert conn.status == 200
      assert is_binary(session_id)

      assert %{"result" => %{"serverInfo" => %{"name" => "shelley-plants"}}} =
               json_response(conn, 200)
    end
  end

  describe "list_plants and get_plant" do
    test "list_plants returns the catalog", %{conn: conn} do
      plant = plant_fixture(%{common_name: "MCP List Test", latin_name: "Mcplisttestus uniquus"})
      {_admin_user, raw_token} = admin_token_fixture(["read"])
      {conn, session_id} = initialize(conn, raw_token)

      resp = call_tool(conn, raw_token, session_id, "list_plants", %{})
      body = json_response(resp, 200)
      text = get_in(body, ["result", "content", Access.at(0), "text"])
      plants = Jason.decode!(text)

      assert Enum.any?(plants, &(&1["id"] == plant.id))
    end

    test "get_plant returns a single plant with moisture_unacceptable", %{conn: conn} do
      plant =
        plant_fixture(%{
          common_name: "MCP Get Test",
          latin_name: "Mcpgettestus uniquus",
          moisture_unacceptable: ["wet", "dry"]
        })

      {_admin_user, raw_token} = admin_token_fixture(["read"])
      {conn, session_id} = initialize(conn, raw_token)

      resp = call_tool(conn, raw_token, session_id, "get_plant", %{"id" => plant.id})
      body = json_response(resp, 200)
      text = get_in(body, ["result", "content", Access.at(0), "text"])
      returned = Jason.decode!(text)

      assert returned["id"] == plant.id
      assert returned["moisture_unacceptable"] == ["wet", "dry"]
    end

    test "get_plant with unknown id returns a tool error, not a crash", %{conn: conn} do
      {_admin_user, raw_token} = admin_token_fixture(["read"])
      {conn, session_id} = initialize(conn, raw_token)

      resp = call_tool(conn, raw_token, session_id, "get_plant", %{"id" => Ecto.UUID.generate()})
      body = json_response(resp, 200)
      assert get_in(body, ["result", "isError"]) == true
    end
  end

  describe "scope enforcement" do
    test "a read-only token cannot call create_plant", %{conn: conn} do
      {_admin_user, raw_token} = admin_token_fixture(["read"])
      {conn, session_id} = initialize(conn, raw_token)

      resp =
        call_tool(conn, raw_token, session_id, "create_plant", %{
          "common_name" => "Nope",
          "latin_name" => "Nopus nopus",
          "flower_color" => "x",
          "bloom_time" => "x",
          "height" => "x",
          "chelsea_chop" => false,
          "light_requirements" => "x",
          "moisture" => "x",
          "plant_type" => "perennial",
          "native_ontario" => true,
          "locally_native" => true,
          "deer_resistant" => true
        })

      body = json_response(resp, 200)
      assert get_in(body, ["result", "isError"]) == true

      text = get_in(body, ["result", "content", Access.at(0), "text"])
      assert text =~ "write"
    end
  end

  describe "admin enforcement" do
    test "a non-admin user's write-scoped token cannot create a plant", %{conn: conn} do
      user = user_fixture()

      {:ok, raw_token, _} =
        Accounts.create_mcp_token(user, %{"name" => "t", "scopes" => ["read", "write"]})

      {conn, session_id} = initialize(conn, raw_token)

      resp =
        call_tool(conn, raw_token, session_id, "create_plant", %{
          "common_name" => "Nope",
          "latin_name" => "Nopus adminus",
          "flower_color" => "x",
          "bloom_time" => "x",
          "height" => "x",
          "chelsea_chop" => false,
          "light_requirements" => "x",
          "moisture" => "x",
          "plant_type" => "perennial",
          "native_ontario" => true,
          "locally_native" => true,
          "deer_resistant" => true
        })

      body = json_response(resp, 200)
      assert get_in(body, ["result", "isError"]) == true

      text = get_in(body, ["result", "content", Access.at(0), "text"])
      assert text =~ "admin"
    end
  end

  describe "create_plant, update_plant, delete_plant" do
    test "an admin write token can create, update, and delete a plant", %{conn: conn} do
      {_admin_user, raw_token} = admin_token_fixture(["read", "write"])
      {conn, session_id} = initialize(conn, raw_token)

      create_resp =
        call_tool(conn, raw_token, session_id, "create_plant", %{
          "common_name" => "MCP CRUD Test",
          "latin_name" => "Mcpcrudtestus uniquus",
          "flower_color" => "Blue",
          "bloom_time" => "June",
          "height" => "30cm",
          "chelsea_chop" => false,
          "light_requirements" => "Full sun",
          "moisture" => "Average",
          "plant_type" => "perennial",
          "native_ontario" => true,
          "locally_native" => true,
          "deer_resistant" => true,
          "moisture_level" => "average",
          "moisture_unacceptable" => ["wet"]
        })

      created_body = json_response(create_resp, 200)
      refute get_in(created_body, ["result", "isError"]) == true
      created_text = get_in(created_body, ["result", "content", Access.at(0), "text"])
      created = Jason.decode!(created_text)
      assert created["moisture_unacceptable"] == ["wet"]

      update_resp =
        call_tool(conn, raw_token, session_id, "update_plant", %{
          "id" => created["id"],
          "common_name" => "MCP CRUD Test Updated"
        })

      updated_body = json_response(update_resp, 200)
      updated_text = get_in(updated_body, ["result", "content", Access.at(0), "text"])
      updated = Jason.decode!(updated_text)
      assert updated["common_name"] == "MCP CRUD Test Updated"

      delete_resp =
        call_tool(conn, raw_token, session_id, "delete_plant", %{"id" => created["id"]})

      delete_body = json_response(delete_resp, 200)
      delete_text = get_in(delete_body, ["result", "content", Access.at(0), "text"])
      assert Jason.decode!(delete_text)["deleted"] == true

      assert_raise Ecto.NoResultsError, fn -> ShelleyPlants.Catalog.get_plant!(created["id"]) end
    end

    test "create_plant rejects an invalid moisture_unacceptable value", %{conn: conn} do
      {_admin_user, raw_token} = admin_token_fixture(["read", "write"])
      {conn, session_id} = initialize(conn, raw_token)

      resp =
        call_tool(conn, raw_token, session_id, "create_plant", %{
          "common_name" => "Bad Moisture",
          "latin_name" => "Badmoisturus uniquus",
          "flower_color" => "x",
          "bloom_time" => "x",
          "height" => "x",
          "chelsea_chop" => false,
          "light_requirements" => "x",
          "moisture" => "x",
          "plant_type" => "perennial",
          "native_ontario" => true,
          "locally_native" => true,
          "deer_resistant" => true,
          "moisture_unacceptable" => ["soggy"]
        })

      # Invalid enum values are rejected by the tool's own input schema
      # validation before the changeset ever runs.
      body = json_response(resp, 200)
      assert body["error"] || get_in(body, ["result", "isError"]) == true
    end
  end
end
