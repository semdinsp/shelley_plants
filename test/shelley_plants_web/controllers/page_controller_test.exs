defmodule ShelleyPlantsWeb.PageControllerTest do
  use ShelleyPlantsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Biosphere"
    assert html_response(conn, 200) =~ "Native Plants"
    assert html_response(conn, 200) =~ "Dr. Shelley Ball"
  end
end
