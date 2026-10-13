defmodule ShelleyPlantsWeb.CrawlerControllerTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import ShelleyPlants.CatalogFixtures

  alias ShelleyPlantsWeb.Endpoint

  test "sitemap.xml lists the main pages, category pages and plant slug URLs", %{conn: conn} do
    plant = plant_fixture(%{latin_name: "Aquilegia canadensis"})
    conn = get(conn, ~p"/sitemap.xml")

    assert response_content_type(conn, :xml)
    xml = response(conn, 200)
    base = Endpoint.url()

    for path <- ["/", "/about", "/contact", "/garden-planner", "/plants", "/plants/gallery"] do
      assert xml =~ "<loc>#{base}#{path}</loc>"
    end

    for category <- ~w(Wildflower Grass Shrub Tree) do
      assert xml =~ "<loc>#{base}/plants/gallery?category=#{category}</loc>"
    end

    assert xml =~ "<loc>#{base}/plants/aquilegia-canadensis</loc>"
    assert xml =~ "<lastmod>#{Date.to_iso8601(plant.updated_at)}</lastmod>"
    refute xml =~ plant.id
  end

  test "robots.txt allows crawlers, blocks private paths and points to the sitemap", %{conn: conn} do
    body = conn |> get(~p"/robots.txt") |> response(200)

    assert body =~ "User-agent: *\nAllow: /"
    assert body =~ "Disallow: /mcp\n"
    assert body =~ "Disallow: /users/"
    assert body =~ "Disallow: /admin"
    assert body =~ "Sitemap: #{Endpoint.url()}/sitemap.xml"
  end

  test "llms.txt is short markdown describing the nursery", %{conn: conn} do
    conn = get(conn, ~p"/llms.txt")
    body = response(conn, 200)

    assert [content_type] = get_resp_header(conn, "content-type")
    assert content_type =~ "text/markdown"
    assert body =~ "# Biosphere Native Plants"
    assert body =~ "Dr. Shelley Ball"
    assert body =~ "#{Endpoint.url()}/plants/gallery?category=Wildflower"
    assert body =~ "#{Endpoint.url()}/sitemap.xml"
    assert body =~ "#{Endpoint.url()}/mcp/public"
    assert length(String.split(body, "\n")) < 60
  end
end
