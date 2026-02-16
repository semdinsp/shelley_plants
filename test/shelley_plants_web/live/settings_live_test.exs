defmodule ShelleyPlantsWeb.SettingsLiveTest do
  use ShelleyPlantsWeb.ConnCase

  import Phoenix.LiveViewTest
  import ShelleyPlants.AccountsFixtures

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
end
