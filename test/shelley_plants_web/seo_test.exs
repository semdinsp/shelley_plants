defmodule ShelleyPlantsWeb.SeoTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import ShelleyPlants.CatalogFixtures

  alias ShelleyPlantsWeb.{Endpoint, Seo}

  @columbine %{
    common_name: "Canada Columbine",
    latin_name: "Aquilegia canadensis",
    category: "Wildflower",
    sun_level: "part_shade",
    moisture_level: "average",
    height: ~s(12-24"),
    spread_cm: 30,
    picture: "/images/plants/aquilegia_canadensis_2.jpg",
    ecological_benefit: "Early nectar for hummingbirds and bees. Host plant for moths.",
    chelsea_chop: true
  }

  defp page(conn, path), do: conn |> get(path) |> html_response(200) |> LazyHTML.from_document()

  defp attr(doc, selector, name) do
    doc |> LazyHTML.query(selector) |> LazyHTML.attribute(name) |> List.first()
  end

  defp title(doc), do: doc |> LazyHTML.query("title") |> LazyHTML.text()

  defp json_ld(doc) do
    doc
    |> LazyHTML.query(~s(script[type="application/ld+json"]))
    |> LazyHTML.text()
    |> Jason.decode!()
  end

  defp node(json_ld, type), do: Enum.find(json_ld["@graph"], &(&1["@type"] == type))

  describe "plant page" do
    setup %{conn: conn} do
      plant = plant_fixture(@columbine)
      %{plant: plant, doc: page(conn, ~p"/plants/#{plant}")}
    end

    test "has a one-line, descriptive title", %{doc: doc} do
      assert title(doc) ==
               "Canada Columbine (Aquilegia canadensis), Ontario native wildflower · Biosphere Native Plants"
    end

    test "has a generated meta description of at most ~155 characters", %{doc: doc} do
      description = attr(doc, ~s(meta[name="description"]), "content")

      assert description =~
               "Canada Columbine, Aquilegia canadensis. Ontario native wildflower for part shade, average soil, 12–24in. Early nectar for hummingbirds and bees."

      assert String.length(description) <= 155
    end

    test "canonical, og:url and og:image are absolute URLs", %{doc: doc} do
      base = Endpoint.url()

      assert attr(doc, ~s(link[rel="canonical"]), "href") ==
               base <> "/plants/aquilegia-canadensis"

      assert attr(doc, ~s(meta[property="og:url"]), "content") ==
               base <> "/plants/aquilegia-canadensis"

      assert attr(doc, ~s(meta[property="og:image"]), "content") ==
               base <> "/images/plants/aquilegia_canadensis_2.jpg"

      assert attr(doc, ~s(meta[property="og:locale"]), "content") == "en_CA"
      assert attr(doc, ~s(meta[property="og:site_name"]), "content") == "Biosphere Native Plants"
    end

    test "JSON-LD is valid JSON with Product, Taxon and a breadcrumbed WebPage", %{doc: doc} do
      data = json_ld(doc)
      url = Endpoint.url() <> "/plants/aquilegia-canadensis"

      product = node(data, "Product")
      assert product["name"] == "Canada Columbine"
      assert product["alternateName"] == "Aquilegia canadensis"
      assert product["category"] == "Wildflower"
      assert product["image"] == [Endpoint.url() <> "/images/plants/aquilegia_canadensis_2.jpg"]
      refute Map.has_key?(product, "offers")

      properties = Map.new(product["additionalProperty"], &{&1["name"], &1["value"]})
      assert properties["Native to Ontario"] == "Yes"
      assert properties["Chelsea chop"] == "Yes"
      assert properties["Spread"] == "30 cm"

      taxon = node(data, "Taxon")
      assert taxon["name"] == "Aquilegia canadensis"
      assert taxon["taxonRank"] == "species"
      assert taxon["alternateName"] == "Canada Columbine"

      webpage = node(data, "WebPage")
      assert webpage["about"] == %{"@id" => taxon["@id"]}
      assert webpage["mainEntity"] == %{"@id" => product["@id"]}

      assert %{"@type" => "BreadcrumbList", "itemListElement" => crumbs} = webpage["breadcrumb"]
      assert Enum.map(crumbs, & &1["name"]) == ["Home", "Plants", "Canada Columbine"]
      assert List.last(crumbs)["item"] == url
    end
  end

  test "plant text containing </script> can't break out of the JSON-LD tag", %{conn: conn} do
    plant = plant_fixture(%{ecological_benefit: "Bees love it</script><script>alert(1)</script>"})
    html = conn |> get(~p"/plants/#{plant}") |> html_response(200)

    refute html =~ "</script><script>alert(1)"

    data = html |> LazyHTML.from_document() |> json_ld()

    assert node(data, "Product")["description"] ==
             "Bees love it</script><script>alert(1)</script>"
  end

  test "near-native plants aren't called Ontario native" do
    plant = %ShelleyPlants.Catalog.Plant{
      common_name: "Anise Hyssop",
      latin_name: "Agastache foeniculum",
      category: "Wildflower",
      native_ontario: false,
      near_native: true
    }

    assert Seo.plant_title(plant) == "Anise Hyssop (Agastache foeniculum), near-native wildflower"
  end

  test "long descriptions are cut at a word boundary" do
    text = String.duplicate("pollinator ", 30)
    cut = Seo.truncate(text, 155)

    assert String.length(cut) <= 155
    assert String.ends_with?(cut, "pollinator…")
  end

  describe "list pages" do
    setup do
      plant_fixture(@columbine)
      :ok
    end

    test "category gallery pages have their own canonical URL and an ItemList", %{conn: conn} do
      doc = page(conn, ~p"/plants/gallery?category=Wildflower")

      assert attr(doc, ~s(link[rel="canonical"]), "href") ==
               Endpoint.url() <> "/plants/gallery?category=Wildflower"

      assert title(doc) == "Shop Ontario Native Wildflowers · Biosphere Native Plants"

      collection = node(json_ld(doc), "CollectionPage")

      assert [%{"name" => "Canada Columbine", "url" => url}] =
               collection["mainEntity"]["itemListElement"]

      assert url == Endpoint.url() <> "/plants/aquilegia-canadensis"
    end

    test "the species list is a CollectionPage", %{conn: conn} do
      doc = page(conn, ~p"/plants")

      assert attr(doc, ~s(link[rel="canonical"]), "href") == Endpoint.url() <> "/plants"
      assert node(json_ld(doc), "CollectionPage")["mainEntity"]["numberOfItems"] == 1
    end
  end

  describe "business pages" do
    test "home, about and contact describe the nursery and its founder", %{conn: conn} do
      for path <- ["/", "/about", "/contact"] do
        business = conn |> page(path) |> json_ld() |> node("LocalBusiness")

        assert business["name"] == "Biosphere Native Plants"
        assert business["address"]["addressLocality"] == "Westport"
        assert business["areaServed"]["name"] == "Eastern Ontario"
        assert business["founder"]["name"] == "Shelley Ball"
      end
    end

    test "pages without their own description get the site default", %{conn: conn} do
      doc = page(conn, ~p"/")

      assert title(doc) == "Biosphere Native Plants"
      assert attr(doc, ~s(meta[name="description"]), "content") == Seo.default_description()
      assert attr(doc, ~s(link[rel="canonical"]), "href") == Endpoint.url() <> "/"
    end
  end
end
