defmodule ShelleyPlantsWeb.SettingsLiveTest do
  use ShelleyPlantsWeb.ConnCase

  import Phoenix.LiveViewTest
  import ShelleyPlants.AccountsFixtures

  defp register_and_log_in_admin(%{conn: conn}) do
    user = user_fixture()
    {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
    %{conn: log_in_user(conn, admin_user), user: admin_user}
  end

  describe "Settings page — access" do
    test "guest is redirected to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/settings")
    end

    test "authenticated user can access settings", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/settings")
      assert html =~ "Settings"
      assert html =~ "Language"
    end
  end

  describe "Language preference" do
    setup :register_and_log_in_user

    test "displays current preferred language", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/settings")
      assert html =~ "Preferred language"
    end

    test "saves language preference", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      assert lv
             |> form("#language-form", user: %{preferred_language: "fr"})
             |> render_submit() =~ "Language preference saved"
    end

    test "validates language preference via context", %{conn: _conn} do
      user = user_fixture()

      assert {:error, changeset} =
               ShelleyPlants.Accounts.update_user_preferences(user, %{preferred_language: "de"})

      assert %{preferred_language: ["must be a supported language (en, fr)"]} =
               ShelleyPlants.DataCase.errors_on(changeset)
    end
  end

  describe "Admin section visibility" do
    test "non-admin does not see plant management section", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/settings")
      refute html =~ "Plant catalog management"
    end

    test "admin sees plant management section", %{conn: conn} do
      user = user_fixture()
      {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
      conn = log_in_user(conn, admin_user)
      {:ok, _lv, html} = live(conn, ~p"/settings")
      assert html =~ "Plant catalog management"
      assert html =~ "Add new plant"
      assert html =~ "View all plants"
    end
  end

  describe "MCP tokens visibility" do
    test "non-admin does not see MCP tokens section", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/settings")
      refute html =~ "MCP tokens"
    end

    test "admin sees MCP tokens section", %{conn: conn} do
      user = user_fixture()
      {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
      conn = log_in_user(conn, admin_user)
      {:ok, _lv, html} = live(conn, ~p"/settings")
      assert html =~ "MCP tokens"
    end
  end

  describe "MCP tokens" do
    setup :register_and_log_in_admin

    test "shows empty state with no tokens", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/settings")
      assert html =~ "No MCP tokens yet."
    end

    test "creates a token, shows it in the list, and triggers a client-side copy", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      html =
        lv
        |> form("#create-mcp-token-form", mcp_token: %{name: "claude-desktop"})
        |> render_submit()

      assert html =~ "claude-desktop"
      assert html =~ "copied to your clipboard"
      assert_push_event(lv, "copy-mcp-token", %{token: token})
      assert is_binary(token) and byte_size(token) > 0
    end

    test "rejects a blank token name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      html =
        lv
        |> form("#create-mcp-token-form", mcp_token: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "defaults to read scope only", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      html =
        lv
        |> form("#create-mcp-token-form", mcp_token: %{name: "read-only-client"})
        |> render_submit()

      assert html =~ "read-only-client"
      assert html =~ "read"
      refute html =~ "read, write"
    end

    test "creates a token with both read and write scopes", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      html =
        lv
        |> form("#create-mcp-token-form",
          mcp_token: %{name: "full-access", read: "true", write: "true"}
        )
        |> render_submit()

      assert html =~ "read, write"
    end

    test "rejects a token with no scopes selected", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      html =
        lv
        |> form("#create-mcp-token-form",
          mcp_token: %{name: "no-scopes", read: "false", write: "false"}
        )
        |> render_submit()

      assert html =~ "select at least one scope"
    end

    test "revokes a token", %{conn: conn, user: user} do
      {:ok, _raw_token, mcp_token} =
        ShelleyPlants.Accounts.create_mcp_token(user, %{
          "name" => "old-laptop",
          "scopes" => ["read"]
        })

      {:ok, lv, _html} = live(conn, ~p"/settings")

      html =
        lv
        |> element("[phx-value-id='#{mcp_token.id}']")
        |> render_click()

      assert html =~ "Revoked"
      assert html =~ "Token revoked."
    end

    test "cannot revoke another user's token", %{conn: conn} do
      other_user = user_fixture()

      {:ok, _raw_token, mcp_token} =
        ShelleyPlants.Accounts.create_mcp_token(other_user, %{
          "name" => "not-mine",
          "scopes" => ["read"]
        })

      {:ok, lv, _html} = live(conn, ~p"/settings")

      render_hook(lv, "revoke_mcp_token", %{"id" => mcp_token.id})

      [reloaded] = ShelleyPlants.Accounts.list_mcp_tokens(other_user)
      assert is_nil(reloaded.revoked_at)
    end
  end
end
