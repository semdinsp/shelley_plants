defmodule ShelleyPlantsWeb.GardenLiveTest do
  use ShelleyPlantsWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Garden Planner page" do
    test "renders the page for guests", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Garden Planner"
      assert html =~ "Tell us about your outdoor space"
    end

    test "shows created-by attribution with website and phone links", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Biosphere Native Plants"
      assert html =~ "https://biosphere-native-plants.ca/"
      assert html =~ "tel:+16136176524"
      assert html =~ "613-617-6524"
    end

    test "shows all four form sections", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Garden size"
      assert html =~ "Maximum plant height"
      assert html =~ "Height structure"
      assert html =~ "Sun exposure"
    end

    test "shows all four height structure options", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
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

    test "shows the Generate My Garden Plan CTA button", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/garden-planner")
      assert html =~ "Generate My Garden Plan"
    end

    test "submitting the form shows results", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/garden-planner")

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
      assert html =~ "Plant List"
      assert html =~ "4m × 6m garden"
      assert html =~ "/garden-planner/export?"
      assert html =~ "Download CSV"
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
