defmodule ShelleyPlantsWeb.Admin.GuideController do
  use ShelleyPlantsWeb, :controller

  @moduledoc """
  Renders admin-facing markdown guides as HTML pages.

  Guide markdown lives in `docs/` and is read at compile time via
  `@external_resource`, so the rendered HTML is baked into the compiled
  module — no runtime file access is needed, which means this also works
  correctly inside a release (where `docs/` isn't shipped).

  Only an explicit allowlist of slugs can be served — never an arbitrary
  path — since the slug comes straight from the URL.
  """

  guides_dir = Path.join([__DIR__, "..", "..", "..", "..", "docs"])

  guides = [
    {"editing-plants-and-mcp", "Editing Plants and Using Claude Desktop",
     "admin_guide_editing_plants_and_mcp.md"},
    {"plant-data-fields", "Plant Data Entry Guide", "plant_data_guide_for_shelley.md"},
    {"user-administration", "User Administration", "user_administration.md"}
  ]

  for {slug, title, file} <- guides do
    path = Path.join(guides_dir, file)
    @external_resource path

    markdown = File.read!(path)
    html = MDEx.to_html!(markdown, sanitize: MDEx.Document.default_sanitize_options())

    defp guide_html(unquote(slug)), do: unquote(html)
    defp guide_title(unquote(slug)), do: unquote(title)
  end

  defp guide_html(_), do: nil
  defp guide_title(_), do: nil

  @doc """
  The slug/title pairs to link from admin pages, in display order.
  """
  def index, do: unquote(Enum.map(guides, fn {slug, title, _file} -> {slug, title} end))

  def show(conn, %{"slug" => slug}) do
    case guide_html(slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(ShelleyPlantsWeb.ErrorHTML)
        |> render(:"404")

      html ->
        render(conn, :show, page_title: guide_title(slug), guide_html: html)
    end
  end
end
