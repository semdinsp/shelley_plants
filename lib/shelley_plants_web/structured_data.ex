defmodule ShelleyPlantsWeb.StructuredData do
  @moduledoc """
  schema.org JSON-LD for the public pages, built as plain maps. Pages assign
  the result to `:json_ld` and the root layout encodes it (see
  `ShelleyPlantsWeb.Seo`).

  Only facts the site already shows are used. Plant offers (price,
  availability) are left out because the catalogue has no price or stock data.
  """

  alias ShelleyPlants.Catalog.Plant
  alias ShelleyPlantsWeb.Seo

  @context "https://schema.org"

  # ── The nursery ─────────────────────────────────────────────────────────────

  @doc "The nursery as a LocalBusiness, with its founder."
  def business do
    %{
      "@type" => "LocalBusiness",
      "@id" => business_id(),
      "name" => Seo.site_name(),
      "url" => Seo.base_url() <> "/",
      "logo" => Seo.absolute_url("/images/biologo.jpg"),
      "image" => Seo.absolute_url("/images/home/echinacea_purpurea_hero.jpg"),
      "description" => Seo.default_description(),
      "telephone" => "+1-613-617-6524",
      "address" => %{
        "@type" => "PostalAddress",
        "streetAddress" => "1107 Althorpe Road",
        "addressLocality" => "Westport",
        "addressRegion" => "ON",
        "postalCode" => "K0G 1X0",
        "addressCountry" => "CA"
      },
      "areaServed" => %{"@type" => "AdministrativeArea", "name" => "Eastern Ontario"},
      "founder" => founder(),
      "foundingDate" => "2025-05"
    }
  end

  defp founder do
    %{
      "@type" => "Person",
      "@id" => Seo.base_url() <> "/about#shelley-ball",
      "name" => "Shelley Ball",
      "honorificPrefix" => "Dr.",
      "description" =>
        "Biologist, educator and storyteller; founder of Biosphere Environmental Education.",
      "url" => Seo.absolute_url("/about"),
      "sameAs" => ["https://canadiangeographic.ca/author/shelley-ball/"]
    }
  end

  defp business_id, do: Seo.base_url() <> "/#business"

  @doc "Home page: the business and the website."
  def home do
    graph([
      business(),
      %{
        "@type" => "WebSite",
        "@id" => Seo.base_url() <> "/#website",
        "url" => Seo.base_url() <> "/",
        "name" => Seo.site_name(),
        "publisher" => %{"@id" => business_id()},
        "inLanguage" => "en-CA"
      }
    ])
  end

  @doc "About or contact page: the business plus an AboutPage/ContactPage node."
  def business_page(type, path, title) when type in ["AboutPage", "ContactPage"] do
    graph([
      business(),
      %{
        "@type" => type,
        "@id" => Seo.absolute_url(path),
        "url" => Seo.absolute_url(path),
        "name" => title,
        "about" => %{"@id" => business_id()}
      }
    ])
  end

  # ── Plant pages ─────────────────────────────────────────────────────────────

  @doc "Plant detail page: Product, Taxon and WebPage (with breadcrumbs)."
  def plant(%Plant{} = plant) do
    url = Seo.absolute_url("/plants/#{plant.slug}")

    graph([
      plant_product(plant, url),
      %{
        "@type" => "Taxon",
        "@id" => url <> "#taxon",
        "name" => Seo.latin_name(plant),
        "taxonRank" => taxon_rank(plant),
        "alternateName" => plant.common_name
      },
      %{
        "@type" => "WebPage",
        "@id" => url,
        "url" => url,
        "name" => Seo.full_title(Seo.plant_title(plant)),
        "description" => Seo.plant_description(plant),
        "about" => %{"@id" => url <> "#taxon"},
        "mainEntity" => %{"@id" => url <> "#product"},
        "breadcrumb" =>
          breadcrumbs([
            {"Home", Seo.base_url() <> "/"},
            {"Plants", Seo.absolute_url("/plants")},
            {plant.common_name, url}
          ])
      }
    ])
  end

  defp plant_product(plant, url) do
    %{
      "@type" => "Product",
      "@id" => url <> "#product",
      "name" => plant.common_name,
      "alternateName" => Seo.latin_name(plant),
      "description" => plant.ecological_benefit || Seo.plant_description(plant),
      "image" => if(plant.picture, do: [Seo.absolute_url(plant.picture)], else: []),
      "url" => url,
      "category" => plant.category,
      "brand" => %{"@type" => "Organization", "@id" => business_id(), "name" => Seo.site_name()},
      "additionalProperty" => plant_properties(plant)
    }
    |> reject_blank()
  end

  @doc "Every attribute the plant page shows, as schema.org PropertyValues."
  def plant_properties(%Plant{} = plant) do
    [
      {"Light", plant.light_requirements},
      {"Sun exposure", Seo.sun_label(plant.sun_level)},
      {"Moisture", plant.moisture},
      {"Soil moisture", Seo.moisture_label(plant.moisture_level)},
      {"Height", plant.height},
      {"Spread", plant.spread_cm && "#{plant.spread_cm} cm"},
      {"Bloom time", plant.bloom_time},
      {"Flower colour", plant.flower_color},
      {"Plant type", plant.plant_type && String.capitalize(plant.plant_type)},
      {"Ecological benefit", plant.ecological_benefit},
      {"Native to Ontario", yes_no(plant.native_ontario)},
      {"Locally native", yes_no(plant.locally_native)},
      {"Near-native", plant.near_native && "Yes"},
      {"Deer resistant", yes_no(plant.deer_resistant)},
      {"Chelsea chop", plant.chelsea_chop && "Yes"}
    ]
    |> Enum.reject(fn {_name, value} -> value in [nil, false, ""] end)
    |> Enum.map(fn {name, value} ->
      %{"@type" => "PropertyValue", "name" => name, "value" => value}
    end)
  end

  defp taxon_rank(plant) do
    cond do
      plant.latin_name =~ ~r/\bvar\./ -> "variety"
      plant.latin_name =~ ~r/\bssp\.|\bsubsp\./ -> "subspecies"
      true -> "species"
    end
  end

  # ── Plant lists ─────────────────────────────────────────────────────────────

  @doc "Species list or gallery page: a CollectionPage listing the plants shown."
  def collection(path, title, description, plants) do
    url = Seo.absolute_url(path)

    graph([
      %{
        "@type" => "CollectionPage",
        "@id" => url,
        "url" => url,
        "name" => title,
        "description" => description,
        "isPartOf" => %{"@id" => Seo.base_url() <> "/#website"},
        "mainEntity" => %{
          "@type" => "ItemList",
          "numberOfItems" => length(plants),
          "itemListElement" =>
            plants
            |> Enum.with_index(1)
            |> Enum.map(fn {plant, position} ->
              %{
                "@type" => "ListItem",
                "position" => position,
                "name" => plant.common_name,
                "url" => Seo.absolute_url("/plants/#{plant.slug}")
              }
            end)
        }
      }
    ])
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  defp graph(nodes), do: %{"@context" => @context, "@graph" => nodes}

  defp breadcrumbs(items) do
    %{
      "@type" => "BreadcrumbList",
      "itemListElement" =>
        items
        |> Enum.with_index(1)
        |> Enum.map(fn {{name, url}, position} ->
          %{"@type" => "ListItem", "position" => position, "name" => name, "item" => url}
        end)
    }
  end

  defp yes_no(true), do: "Yes"
  defp yes_no(_), do: "No"

  defp reject_blank(map), do: Map.reject(map, fn {_k, v} -> v in [nil, "", []] end)
end
