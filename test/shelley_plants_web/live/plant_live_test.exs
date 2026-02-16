defmodule ShelleyPlantsWeb.PlantLiveTest do
  use ShelleyPlantsWeb.ConnCase

  import Phoenix.LiveViewTest
  import ShelleyPlants.AccountsFixtures
  import ShelleyPlants.CatalogFixtures

  @create_attrs %{
    common_name: "Blue Wild Indigo",
    latin_name: "Baptisia australis",
    flower_color: "Blue",
    bloom_time: "May-June",
    height: "90-120cm",
    chelsea_chop: false,
    light_requirements: "Full sun",
    moisture: "Average to dry",
    plant_type: "perennial",
    native_ontario: true,
    locally_native: false,
    ecological_benefit: "Nitrogen fixer, attracts bees",
    deer_resistant: true,
    notes: "Slow to establish"
  }

  @update_attrs %{
    common_name: "Blue Wild Indigo (updated)",
    latin_name: "Baptisia australis",
    flower_color: "Deep blue",
    bloom_time: "May-July",
    height: "100-130cm",
    chelsea_chop: false,
    light_requirements: "Full sun",
    moisture: "Dry to average",
    plant_type: "perennial",
    native_ontario: true,
    locally_native: false,
    ecological_benefit: "Nitrogen fixer",
    deer_resistant: true,
    notes: ""
  }

  @invalid_attrs %{
    common_name: "",
    latin_name: "",
    plant_type: ""
  }

  defp register_and_log_in_admin(%{conn: conn}) do
    user = user_fixture()
    {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
    %{conn: log_in_user(conn, admin_user), user: admin_user}
  end

  describe "Index — public access" do
    setup do
      plant = plant_fixture()
      %{plant: plant}
    end

    test "guests can list plants", %{conn: conn, plant: plant} do
      {:ok, _lv, html} = live(conn, ~p"/plants")
      assert html =~ "Native Plants"
      assert html =~ plant.common_name
    end

    test "logged-in non-admin can list plants", %{conn: conn, plant: plant} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/plants")
      assert html =~ plant.common_name
    end

    test "guests do not see New Plant button", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/plants")
      refute html =~ "New Plant"
    end

    test "non-admin users do not see Edit or Delete links", %{conn: conn, plant: plant} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/plants")
      refute has_element?(lv, "#plants-#{plant.id} a", "Edit")
      refute has_element?(lv, "#plants-#{plant.id} a", "Delete")
    end

    test "admin sees New Plant button", %{conn: conn} do
      user = user_fixture()
      {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
      conn = log_in_user(conn, admin_user)
      {:ok, _lv, html} = live(conn, ~p"/plants")
      assert html =~ "New Plant"
    end

    test "admin sees Edit and Delete links", %{conn: conn, plant: plant} do
      user = user_fixture()
      {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
      conn = log_in_user(conn, admin_user)
      {:ok, lv, _html} = live(conn, ~p"/plants")
      assert has_element?(lv, "#plants-#{plant.id} a", "Edit")
      assert has_element?(lv, "#plants-#{plant.id} a", "Delete")
    end
  end

  describe "Index — admin CRUD" do
    setup :register_and_log_in_admin

    setup do
      plant = plant_fixture()
      %{plant: plant}
    end

    test "saves new plant", %{conn: conn} do
      {:ok, index_lv, _html} = live(conn, ~p"/plants")

      assert {:ok, form_lv, _} =
               index_lv
               |> element("a", "New Plant")
               |> render_click()
               |> follow_redirect(conn, ~p"/plants/new")

      assert render(form_lv) =~ "New Plant"

      assert form_lv
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_lv, _html} =
               form_lv
               |> form("#plant-form", plant: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plants")

      assert render(index_lv) =~ "Plant created successfully"
      assert render(index_lv) =~ "Blue Wild Indigo"
    end

    test "updates plant from listing", %{conn: conn, plant: plant} do
      {:ok, index_lv, _html} = live(conn, ~p"/plants")

      assert {:ok, form_lv, _html} =
               index_lv
               |> element("#plants-#{plant.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/plants/#{plant}/edit")

      assert render(form_lv) =~ "Edit Plant"

      assert form_lv
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_lv, _html} =
               form_lv
               |> form("#plant-form", plant: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plants")

      assert render(index_lv) =~ "Plant updated successfully"
      assert render(index_lv) =~ "Blue Wild Indigo (updated)"
    end

    test "deletes plant from listing", %{conn: conn, plant: plant} do
      {:ok, index_lv, _html} = live(conn, ~p"/plants")
      assert index_lv |> element("#plants-#{plant.id} a", "Delete") |> render_click()
      refute has_element?(index_lv, "#plants-#{plant.id}")
    end
  end

  describe "Show — public access" do
    setup do
      plant = plant_fixture()
      %{plant: plant}
    end

    test "guests can view a plant", %{conn: conn, plant: plant} do
      {:ok, _lv, html} = live(conn, ~p"/plants/#{plant}")
      assert html =~ plant.common_name
      assert html =~ plant.latin_name
    end

    test "non-admin does not see Edit button", %{conn: conn, plant: plant} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/plants/#{plant}")
      refute has_element?(lv, "a", "Edit plant")
    end

    test "admin sees Edit button", %{conn: conn, plant: plant} do
      user = user_fixture()
      {:ok, admin_user} = ShelleyPlants.Accounts.set_user_admin(user, true)
      conn = log_in_user(conn, admin_user)
      {:ok, lv, _html} = live(conn, ~p"/plants/#{plant}")
      assert has_element?(lv, "a", "Edit plant")
    end
  end

  describe "Show — admin edit from show" do
    setup :register_and_log_in_admin

    setup do
      plant = plant_fixture()
      %{plant: plant}
    end

    test "updates plant and returns to show", %{conn: conn, plant: plant} do
      {:ok, show_lv, _html} = live(conn, ~p"/plants/#{plant}")

      assert {:ok, form_lv, _} =
               show_lv
               |> element("a", "Edit plant")
               |> render_click()
               |> follow_redirect(conn, ~p"/plants/#{plant}/edit?return_to=show")

      assert render(form_lv) =~ "Edit Plant"

      assert {:ok, show_lv, _html} =
               form_lv
               |> form("#plant-form", plant: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plants/#{plant}")

      assert render(show_lv) =~ "Plant updated successfully"
      assert render(show_lv) =~ "Blue Wild Indigo (updated)"
    end
  end

  describe "Form — access control" do
    test "guest is redirected from new plant form", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/plants/new")
    end

    test "non-admin is redirected from new plant form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/plants/new")
    end

    test "non-admin is redirected from edit plant form", %{conn: conn} do
      plant = plant_fixture()
      user = user_fixture()
      conn = log_in_user(conn, user)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/plants/#{plant}/edit")
    end
  end

  describe "Form — photo upload UI" do
    setup :register_and_log_in_admin

    test "shows upload drop zone on new plant form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/plants/new")
      assert html =~ "Choose a photo"
      assert html =~ "JPG, PNG or WebP"
    end

    test "shows current photo and delete button when plant has a picture", %{conn: conn} do
      plant = plant_fixture(%{picture: "/images/plants/test.jpg"})
      {:ok, _lv, html} = live(conn, ~p"/plants/#{plant}/edit")
      assert html =~ "/images/plants/test.jpg"
      assert html =~ "Delete photo"
    end

    test "does not show delete button when plant has no picture", %{conn: conn} do
      plant = plant_fixture(%{picture: nil})
      {:ok, _lv, html} = live(conn, ~p"/plants/#{plant}/edit")
      refute html =~ "Delete photo"
    end

    test "clicking delete photo shows undo warning", %{conn: conn} do
      plant = plant_fixture(%{picture: "/images/plants/test.jpg"})
      {:ok, lv, _html} = live(conn, ~p"/plants/#{plant}/edit")

      html = lv |> element("button", "Delete photo") |> render_click()
      assert html =~ "Photo will be removed when you save"
      assert html =~ "Undo"
      refute html =~ "Delete photo"
    end

    test "clicking undo restores the current photo", %{conn: conn} do
      plant = plant_fixture(%{picture: "/images/plants/test.jpg"})
      {:ok, lv, _html} = live(conn, ~p"/plants/#{plant}/edit")

      lv |> element("button", "Delete photo") |> render_click()
      html = lv |> element("button", "Undo") |> render_click()
      assert html =~ "Delete photo"
      refute html =~ "Photo will be removed when you save"
    end

    test "saving with delete_picture set clears the picture field", %{conn: conn} do
      plant = plant_fixture(%{picture: "/images/plants/test.jpg"})
      {:ok, lv, _html} = live(conn, ~p"/plants/#{plant}/edit")

      lv |> element("button", "Delete photo") |> render_click()

      assert {:ok, _index_lv, _html} =
               lv
               |> form("#plant-form", plant: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plants")

      updated = ShelleyPlants.Catalog.get_plant!(plant.id)
      assert updated.picture == nil
    end
  end
end
