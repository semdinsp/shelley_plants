defmodule ShelleyPlantsWeb.CrawlerController do
  @moduledoc """
  Files for search engines and AI crawlers: /sitemap.xml, /robots.txt and
  /llms.txt. All absolute URLs come from the endpoint's configured URL.
  """
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.Catalog
  alias ShelleyPlantsWeb.Seo

  @categories ~w(Wildflower Grass Shrub Tree)

  # Listed in robots.txt as off limits to crawlers.
  @disallowed ~w(/users/ /settings /admin /mcp /dev/ /newsletter/unsubscribe/)

  def sitemap(conn, _params) do
    plants = Catalog.list_plants()
    latest = plants |> Enum.map(& &1.updated_at) |> Enum.max(DateTime, fn -> nil end)

    pages =
      [
        {"/", nil},
        {"/about", nil},
        {"/contact", nil},
        {"/garden-planner", nil},
        {"/plants", latest},
        {"/plants/gallery", latest}
      ] ++
        Enum.map(@categories, &{"/plants/gallery?category=#{&1}", latest}) ++
        Enum.map(plants, &{"/plants/#{&1.slug}", &1.updated_at})

    urls =
      Enum.map(pages, fn {path, lastmod} ->
        [
          "  <url>\n    <loc>",
          xml_escape(Seo.absolute_url(path)),
          "</loc>\n",
          if(lastmod, do: ["    <lastmod>", Date.to_iso8601(lastmod), "</lastmod>\n"], else: []),
          "  </url>\n"
        ]
      end)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, [
      ~s(<?xml version="1.0" encoding="UTF-8"?>\n),
      ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n),
      urls,
      "</urlset>\n"
    ])
  end

  def robots(conn, _params) do
    body = """
    # Biosphere Native Plants: all crawlers welcome, including AI crawlers.
    User-agent: *
    Allow: /
    #{Enum.map_join(@disallowed, "\n", &"Disallow: #{&1}")}

    Sitemap: #{Seo.absolute_url("/sitemap.xml")}
    """

    conn |> put_resp_content_type("text/plain") |> send_resp(200, body)
  end

  def llms(conn, _params) do
    url = &Seo.absolute_url/1

    body = """
    # Biosphere Native Plants

    > An Ontario native plant nursery near Westport, in Eastern Ontario, Canada.

    Biosphere Native Plants grows and sells Ontario native wildflowers, grasses, shrubs and
    trees for gardens that support pollinators, birds and other wildlife. The nursery opened
    in May 2025 and is run by Dr. Shelley Ball, a biologist (Ph.D. in evolutionary ecology and
    population genetics), educator and founder of Biosphere Environmental Education, with
    nearly 30 years of teaching experience and a background in DNA barcoding research. Each
    plant page lists light, moisture, height, bloom time, flower colour, native status and
    ecological benefits.

    ## Plants

    - [All plants (shop)](#{url.("/plants/gallery")}): photo gallery of every species
    - [Wildflowers](#{url.("/plants/gallery?category=Wildflower")})
    - [Grasses](#{url.("/plants/gallery?category=Grass")})
    - [Shrubs](#{url.("/plants/gallery?category=Shrub")})
    - [Trees](#{url.("/plants/gallery?category=Tree")})
    - [Species list](#{url.("/plants")}): every species with growing conditions in one table
    - [Garden planner](#{url.("/garden-planner")}): suggests a planting list for a garden's size, sun and moisture

    ## Buying and contact

    - Visit the nursery: 1107 Althorpe Road, Westport, ON K0G 1X0 (15 minutes south of Perth)
    - Phone: 613-617-6524
    - [Contact form and newsletter signup](#{url.("/contact")})
    - [About Dr. Shelley Ball](#{url.("/about")})

    ## For AI agents

    - A public, read-only MCP endpoint for searching the plant catalogue is available at
      #{url.("/mcp/public")} (Streamable HTTP, no authentication). Tools: search_plants,
      get_plant, list_filters, recommend_plants.
    - [Sitemap](#{url.("/sitemap.xml")})
    """

    conn |> put_resp_content_type("text/markdown") |> send_resp(200, body)
  end

  defp xml_escape(text), do: text |> Plug.HTML.html_escape_to_iodata()
end
