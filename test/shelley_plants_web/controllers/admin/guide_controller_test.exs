defmodule ShelleyPlantsWeb.Admin.GuideControllerTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import ShelleyPlants.AccountsFixtures

  defp admin_conn(conn) do
    user = user_fixture()
    {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user, true)
    log_in_user(conn, admin)
  end

  describe "GET /admin/guides/:slug" do
    test "redirects guests to log-in", %{conn: conn} do
      conn = get(conn, ~p"/admin/guides/editing-plants-and-mcp")
      assert redirected_to(conn) =~ "/users/log-in"
    end

    test "redirects non-admin users to home", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      conn = get(conn, ~p"/admin/guides/editing-plants-and-mcp")
      assert redirected_to(conn) == ~p"/"
    end

    test "renders the editing-plants-and-mcp guide for admins", %{conn: conn} do
      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/guides/editing-plants-and-mcp")

      html = html_response(conn, 200)
      assert html =~ "Editing Plants and Using Claude Desktop"
      assert html =~ "MCP tokens"
    end

    test "renders the plant-data-fields guide for admins", %{conn: conn} do
      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/guides/plant-data-fields")

      html = html_response(conn, 200)
      assert html =~ "Plant Data Entry Guide"
    end

    test "renders the user-administration guide for admins", %{conn: conn} do
      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/guides/user-administration")

      html = html_response(conn, 200)
      assert html =~ "User Administration"
    end

    test "returns 404 for an unknown slug", %{conn: conn} do
      conn = admin_conn(conn)
      conn = get(conn, ~p"/admin/guides/does-not-exist")
      assert html_response(conn, 404)
    end
  end
end
