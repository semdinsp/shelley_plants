defmodule ShelleyPlantsWeb.ErrorHTMLTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders branded 404.html with a link home" do
    html = render_to_string(ShelleyPlantsWeb.ErrorHTML, "404", "html", [])

    assert html =~ "Page not found"
    assert html =~ "Biosphere Native Plants"
    assert html =~ ~s(href="/")
    assert html =~ "Back to home"
  end

  test "renders branded 500.html with a link home" do
    html = render_to_string(ShelleyPlantsWeb.ErrorHTML, "500", "html", [])

    assert html =~ "Something went wrong"
    assert html =~ "Biosphere Native Plants"
    assert html =~ ~s(href="/")
    assert html =~ "Back to home"
  end

  test "falls back to the plain status message for other errors" do
    assert render_to_string(ShelleyPlantsWeb.ErrorHTML, "403", "html", []) == "Forbidden"
  end

  test "unknown routes return the branded 404 page", %{conn: conn} do
    conn = get(conn, "/this-page-does-not-exist")
    html = html_response(conn, 404)

    assert html =~ "Page not found"
    assert html =~ "Back to home"
  end
end
