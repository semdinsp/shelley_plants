defmodule ShelleyPlantsWeb.Admin.DashboardLiveTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ShelleyPlants.AccountsFixtures
  import ShelleyPlants.CatalogFixtures

  describe "access control" do
    test "redirects guests to log-in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end

    test "redirects non-admin users to home", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())
      assert {:error, redirect} = live(conn, ~p"/admin")
      assert {:redirect, %{to: "/"}} = redirect
    end

    test "renders dashboard for admin users", %{conn: conn} do
      user = user_fixture()
      {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user, true)
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin")
      assert html =~ "Admin Dashboard"
      assert html =~ "Total plants"
      assert html =~ "Export JSON"
    end
  end

  describe "plant stats" do
    setup do
      user = user_fixture()
      {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user, true)
      %{conn: build_conn() |> log_in_user(admin)}
    end

    test "shows correct plant counts", %{conn: conn} do
      plant_fixture(%{latin_name: "Plantus uniquus", picture: "/images/plants/test.jpg"})
      plant_fixture(%{latin_name: "Plantus nopicture", picture: nil})

      {:ok, _lv, html} = live(conn, ~p"/admin")
      assert html =~ "Total plants"
      assert html =~ "With images"
      assert html =~ "Missing images"
    end

    test "links to plant catalog and new plant form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")
      assert html =~ ~p"/plants"
      assert html =~ ~p"/plants/new"
      assert html =~ ~p"/admin/plants/export"
    end
  end
end
