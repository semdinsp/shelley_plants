defmodule ShelleyPlantsWeb.Seo do
  @moduledoc """
  Page metadata for search engines, link previews and AI crawlers.

  Pages set any of these assigns, and the root layout renders the tags
  (falling back to site-wide defaults):

    * `:page_title` — shown as "<title> · Biosphere Native Plants"
    * `:meta_description`
    * `:canonical_path` — path (and query, if it identifies the page)
    * `:og_image` — path or absolute URL
    * `:json_ld` — a schema.org map (see `ShelleyPlantsWeb.StructuredData`)
    * `:robots` — e.g. "noindex" for pages that shouldn't be in search results

  Absolute URLs come from the endpoint's configured URL
  (https://biosphere-native-plants.ca in production), never a fly.dev host.
  """

  use Phoenix.Component

  alias ShelleyPlants.Catalog.Plant

  @site_name "Biosphere Native Plants"
  @default_description "Biosphere Native Plants is an Eastern Ontario native plant nursery " <>
                         "near Westport, run by biologist Dr. Shelley Ball. Ontario native " <>
                         "wildflowers, grasses, shrubs and trees for pollinator and wildlife gardens."
  @default_og_image "/images/home/echinacea_purpurea_hero.jpg"
  @description_length 155

  def site_name, do: @site_name
  def default_description, do: @default_description

  @doc "The site's absolute base URL, e.g. https://biosphere-native-plants.ca"
  def base_url, do: ShelleyPlantsWeb.Endpoint.url()

  @doc "Turns a path into an absolute URL. Absolute URLs pass through unchanged."
  def absolute_url("http" <> _ = url), do: url
  def absolute_url("/" <> _ = path), do: base_url() <> path

  # ── Root layout tags ────────────────────────────────────────────────────────

  attr :page_title, :string, default: nil

  @doc """
  The <title> tag, as a live_title so LiveView page_title changes update it.

  The slot content must stay on one line: any whitespace around it ends up in
  the title ("Canada Columbine\\n     · Biosphere Native Plants").
  """
  def title_tag(assigns) do
    assigns = assign(assigns, title: assigns.page_title && squish(assigns.page_title))

    ~H"""
    <.live_title default={site_name()} suffix={@title && " · " <> site_name()}>{@title}</.live_title>
    """
  end

  attr :page, :map, required: true, doc: "the page's assigns"

  @doc "Renders description, canonical, robots, Open Graph, Twitter and JSON-LD tags."
  def meta_tags(assigns) do
    page = assigns.page

    assigns =
      assign(assigns,
        title: full_title(page[:page_title]),
        description: page[:meta_description] || @default_description,
        canonical: page[:canonical_path] && absolute_url(page[:canonical_path]),
        image: absolute_url(page[:og_image] || @default_og_image),
        robots: page[:robots],
        json_ld: page[:json_ld]
      )

    ~H"""
    <meta name="description" content={@description} />
    <meta :if={@robots} name="robots" content={@robots} />
    <link :if={@canonical} rel="canonical" href={@canonical} />
    <meta property="og:site_name" content="Biosphere Native Plants" />
    <meta property="og:locale" content="en_CA" />
    <meta property="og:type" content="website" />
    <meta property="og:title" content={@title} />
    <meta property="og:description" content={@description} />
    <meta property="og:image" content={@image} />
    <meta :if={@canonical} property="og:url" content={@canonical} />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={@title} />
    <meta name="twitter:description" content={@description} />
    <meta name="twitter:image" content={@image} />
    <script :if={@json_ld} type="application/ld+json">
      <%= Phoenix.HTML.raw(encode_json_ld(@json_ld)) %>
    </script>
    """
  end

  @doc "The page title with the site name, on one line."
  def full_title(nil), do: @site_name
  def full_title(title), do: "#{squish(title)} · #{@site_name}"

  @doc """
  Encodes JSON-LD for a <script> tag. `<`, `>` and `&` are escaped as
  \\u003c etc., so text like "</script>" in plant data can't end the tag.
  """
  def encode_json_ld(data), do: Jason.encode!(data, escape: :html_safe)

  # ── Plant list pages ────────────────────────────────────────────────────────

  @plural %{
    "Wildflower" => "wildflowers",
    "Grass" => "grasses",
    "Shrub" => "shrubs",
    "Tree" => "trees"
  }

  @doc """
  Meta assigns for the shop gallery (`:gallery`) or species list
  (`:species_list`), optionally for one category. Category pages get their
  own canonical URL (with ?category=) so each is indexed as its own page.
  """
  def plant_list_meta(page, category, plants) do
    {base_path, title, description} = plant_list_text(page, category && @plural[category])
    path = if category, do: base_path <> "?category=" <> category, else: base_path

    [
      page_title: title,
      meta_description: description,
      canonical_path: path,
      json_ld:
        ShelleyPlantsWeb.StructuredData.collection(path, full_title(title), description, plants)
    ]
  end

  defp plant_list_text(:gallery, nil) do
    {"/plants/gallery", "Shop Ontario Native Plants",
     "Shop Ontario native wildflowers, grasses, shrubs and trees grown at Biosphere " <>
       "Native Plants near Westport, Eastern Ontario. Plants for pollinators, birds and wildlife."}
  end

  defp plant_list_text(:gallery, plural) do
    {"/plants/gallery", "Shop Ontario Native #{String.capitalize(plural)}",
     "Ontario native #{plural} from Biosphere Native Plants, an Eastern Ontario native " <>
       "plant nursery near Westport. Photos, growing conditions and wildlife value for each."}
  end

  defp plant_list_text(:species_list, nil) do
    {"/plants", "Species List: Ontario Native Plants",
     "Every species at Biosphere Native Plants with its light, moisture, height and " <>
       "native status: Ontario native wildflowers, grasses, shrubs and trees for Eastern Ontario gardens."}
  end

  defp plant_list_text(:species_list, plural) do
    {"/plants", "Species List: Ontario Native #{String.capitalize(plural)}",
     "Ontario native #{plural} at Biosphere Native Plants, with light, moisture, height " <>
       "and native status for each species. For Eastern Ontario gardens."}
  end

  # ── Plant pages ─────────────────────────────────────────────────────────────

  @doc "All meta assigns for a plant detail page."
  def plant_meta(%Plant{} = plant) do
    [
      page_title: plant_title(plant),
      meta_description: plant_description(plant),
      canonical_path: "/plants/#{plant.slug}",
      og_image: plant.picture,
      json_ld: ShelleyPlantsWeb.StructuredData.plant(plant)
    ]
  end

  @doc """
  e.g. "Canada Columbine (Aquilegia canadensis), Ontario native wildflower"
  (the layout adds " · Biosphere Native Plants").
  """
  def plant_title(%Plant{} = plant) do
    "#{plant.common_name} (#{latin_name(plant)}), #{status_and_category(plant)}"
  end

  @doc """
  e.g. "Canada Columbine, Aquilegia canadensis. Ontario native wildflower for
  part shade, average soil, 12–24in. Early nectar for hummingbirds and bees."
  Cut at a word boundary to about 155 characters.
  """
  def plant_description(%Plant{} = plant) do
    conditions =
      [
        sun_label(plant.sun_level),
        moisture_label(plant.moisture_level),
        height_label(plant.height)
      ]
      |> Enum.reject(&is_nil/1)

    summary =
      case conditions do
        [] -> status_and_category(plant, :sentence)
        _ -> "#{status_and_category(plant, :sentence)} for #{Enum.join(conditions, ", ")}"
      end

    [
      "#{plant.common_name}, #{latin_name(plant)}.",
      summary <> ".",
      first_sentence(plant.ecological_benefit) || first_sentence(plant.notes)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> truncate(@description_length)
  end

  @doc "The Latin name without bracketed notes (e.g. former names)."
  def latin_name(%Plant{latin_name: name}),
    do: name |> String.replace(~r/\(.*?\)/, "") |> squish()

  @doc ~s(e.g. "Ontario native", "Near-native" or nil, from the plant's native flags.)
  def native_status(%Plant{native_ontario: true}), do: "Ontario native"
  def native_status(%Plant{near_native: true}), do: "Near-native"
  def native_status(%Plant{}), do: nil

  defp status_and_category(plant, style \\ :title) do
    category = String.downcase(plant.category || "plant")

    case {native_status(plant), style} do
      {nil, :title} -> category
      {nil, :sentence} -> String.capitalize(category)
      {"Near-native", :title} -> "near-native #{category}"
      {status, _} -> "#{status} #{category}"
    end
  end

  def sun_label("full_sun"), do: "full sun"
  def sun_label("part_shade"), do: "part shade"
  def sun_label("full_shade"), do: "full shade"
  def sun_label(_), do: nil

  def moisture_label(level) when level in ~w(wet average dry), do: "#{level} soil"
  def moisture_label("very_dry"), do: "very dry soil"
  def moisture_label(_), do: nil

  # "24-60\"" -> "24–60in"; other formats are kept, with an en dash.
  defp height_label(nil), do: nil

  defp height_label(height) do
    height
    |> squish()
    |> String.replace(~r/\s*[-–]\s*/, "–")
    |> String.replace(~r/"$/, "in")
  end

  defp first_sentence(nil), do: nil

  defp first_sentence(text) do
    case text |> squish() |> String.split(~r/(?<=[.!?])\s/, parts: 2) do
      [""] -> nil
      [sentence | _] -> sentence
    end
  end

  @doc "Cuts text to at most `max` characters at a word boundary, adding an ellipsis."
  def truncate(text, max) do
    if String.length(text) <= max do
      text
    else
      cut = String.slice(text, 0, max - 1)

      cut
      |> String.replace(~r/\s+\S*$/, "")
      |> String.trim_trailing(",;:.")
      |> Kernel.<>("…")
    end
  end

  @doc "Trims text and collapses runs of whitespace (including non-breaking spaces)."
  def squish(text), do: text |> String.replace(~r/[\s\x{00A0}]+/u, " ") |> String.trim()
end
