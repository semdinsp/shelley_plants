defmodule ShelleyPlantsWeb.GardenLiveTest do
  use ShelleyPlantsWeb.ConnCase

  import Phoenix.LiveViewTest
  import ShelleyPlants.CatalogFixtures

  describe "Garden Planner page" do
    test "renders the page for guests", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Garden Planner"
      assert html =~ "Tell us about your outdoor space"
    end

    test "shows the top-level form sections, with Advanced options collapsed", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Garden size"
      assert html =~ "Sun exposure"
      assert html =~ "Moisture level"
      assert html =~ "Advanced options"
      refute html =~ "Maximum plant height"
      refute html =~ "Height structure"
    end

    test "expanding Advanced options reveals max height and height structure", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      html = lv |> element("button", "Advanced options") |> render_click()

      assert html =~ "Maximum plant height"
      assert html =~ "Height structure"
      assert html =~ "Low &amp; uniform"
      assert html =~ "Layered"
      assert html =~ "Mixed / naturalistic"
      assert html =~ "Tall focal points"
    end

    test "shows all three sun exposure options", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Full sun"
      assert html =~ "Part shade"
      assert html =~ "Full shade"
    end

    test "shows all four moisture level options", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Dry"
      assert html =~ "Average"
      assert html =~ "Moist"
      assert html =~ "Wet"
    end

    test "shows the Generate My Garden Plan CTA button", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Generate My Garden Plan"
    end

    test "submitting the form shows results", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      html =
        lv
        |> form("form", %{"width" => "4", "length" => "6", "sun" => "full_sun"})
        |> render_submit()

      assert html =~ "Your garden plan is ready"
      assert html =~ "Plant List"
      assert html =~ "4m × 6m garden"
      assert html =~ "/garden-planner/export?"
      assert html =~ "Download CSV"
    end

    test "submitting with advanced options set (height structure, max height) shows results", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      lv |> element("button", "Advanced options") |> render_click()

      html =
        lv
        |> form("form", %{
          "width" => "4",
          "length" => "6",
          "max_height" => "120",
          "height_structure" => "layered",
          "sun" => "full_sun"
        })
        |> render_submit()

      assert html =~ "Your garden plan is ready"
      assert html =~ "layered from front to back"
    end

    test "submitting the form with moisture selected mentions it in the summary", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      html =
        lv
        |> form("form", %{
          "width" => "4",
          "length" => "6",
          "sun" => "full_sun",
          "moisture" => "wet"
        })
        |> render_submit()

      assert html =~ "wet soil"
    end

    test "shows a weak-match note when most results don't share the requested moisture",
         %{conn: conn} do
      plant_fixture(%{
        common_name: "Weak Match Wet Plant",
        latin_name: "Weakmatchus wetus",
        sun_level: "full_sun",
        moisture_level: "wet"
      })

      for n <- 1..3 do
        plant_fixture(%{
          common_name: "Weak Match Dry Plant #{n}",
          latin_name: "Weakmatchus dryus#{n}",
          sun_level: "full_sun",
          moisture_level: "dry"
        })
      end

      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      html =
        lv
        |> form("form", %{
          "width" => "1",
          "length" => "2",
          "sun" => "full_sun",
          "moisture" => "wet"
        })
        |> render_submit()

      assert html =~ "closest available match"
    end

    test "does not show the weak-match note when most results share the requested moisture",
         %{conn: conn} do
      for n <- 1..3 do
        plant_fixture(%{
          common_name: "Strong Match Wet Plant #{n}",
          latin_name: "Strongmatchus wetus#{n}",
          sun_level: "full_sun",
          moisture_level: "wet"
        })
      end

      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      html =
        lv
        |> form("form", %{
          "width" => "1",
          "length" => "2",
          "sun" => "full_sun",
          "moisture" => "wet"
        })
        |> render_submit()

      refute html =~ "closest available match"
    end

    test "does not show the weak-match note when no moisture is selected", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      html =
        lv
        |> form("form", %{"width" => "3", "length" => "3"})
        |> render_submit()

      refute html =~ "closest available match"
    end

    test "results show the Start over button", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      lv |> form("form", %{"width" => "3", "length" => "3"}) |> render_submit()

      assert has_element?(lv, "button", "Start over")
    end

    test "clicking Start over returns to the form", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

      lv |> form("form", %{"width" => "3", "length" => "3"}) |> render_submit()

      lv |> element("button", "Start over") |> render_click()

      html = render(lv)
      assert html =~ "Generate My Garden Plan"
      refute html =~ "Your garden plan is ready"
    end

    test "nav contains Garden Planner link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Garden Planner"
    end
  end

  describe "old /design-garden URL" do
    test "redirects to /garden-planner", %{conn: conn} do
      conn = get(conn, ~p"/design-garden")
      assert redirected_to(conn) == ~p"/garden-planner"
    end
  end
end
