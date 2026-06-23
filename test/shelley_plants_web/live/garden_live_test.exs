defmodule ShelleyPlantsWeb.GardenLiveTest do
  use ShelleyPlantsWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Design Your Garden page" do
    test "renders the page for guests", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/design-garden")
      assert html =~ "Design Your Garden"
      assert html =~ "Tell us about your outdoor space"
    end

    test "shows all five form sections", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/design-garden")
      assert html =~ "Garden size"
      assert html =~ "Garden shape"
      assert html =~ "Maximum plant height"
      assert html =~ "Height structure"
      assert html =~ "Sun exposure"
    end

    test "shows all five shape options", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/design-garden")
      assert html =~ "Rectangular"
      assert html =~ "Square"
      assert html =~ "Triangular"
      assert html =~ "Circular"
      assert html =~ "Irregular"
    end

    test "shows all four height structure options", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/design-garden")
      assert html =~ "Low &amp; uniform"
      assert html =~ "Layered"
      assert html =~ "Mixed / naturalistic"
      assert html =~ "Tall focal points"
    end

    test "shows all three sun exposure options", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/design-garden")
      assert html =~ "Full sun"
      assert html =~ "Part shade"
      assert html =~ "Full shade"
    end

    test "shows the Generate My Garden Plan CTA button", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/design-garden")
      assert html =~ "Generate My Garden Plan"
    end

    test "submitting the form shows results", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/design-garden")

      html =
        lv
        |> form("form", %{
          "width" => "4",
          "length" => "6",
          "shape" => "rectangular",
          "max_height" => "120",
          "height_structure" => "layered",
          "sun" => "full_sun"
        })
        |> render_submit()

      assert html =~ "Your garden plan is ready"
      assert html =~ "Plant List"
      assert html =~ "Planting Diagram"
      assert html =~ "4m × 6m garden"
    end

    test "results show the Start over button", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/design-garden")

      lv |> form("form", %{"width" => "3", "length" => "3"}) |> render_submit()

      assert has_element?(lv, "button", "Start over")
    end

    test "clicking Start over returns to the form", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/design-garden")

      lv |> form("form", %{"width" => "3", "length" => "3"}) |> render_submit()

      lv |> element("button", "Start over") |> render_click()

      html = render(lv)
      assert html =~ "Generate My Garden Plan"
      refute html =~ "Your garden plan is ready"
    end

    test "nav contains Design Your Garden link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/design-garden")
      assert html =~ "Design Your Garden"
    end
  end
end
