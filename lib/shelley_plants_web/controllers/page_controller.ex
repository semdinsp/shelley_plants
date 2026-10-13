defmodule ShelleyPlantsWeb.PageController do
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.{Catalog, Outreach, Turnstile}
  alias ShelleyPlants.Outreach.NewsletterSubscriber
  alias ShelleyPlantsWeb.StructuredData

  def home(conn, _params) do
    render_home(conn)
  end

  def about(conn, _params) do
    title = "About Dr. Shelley Ball and Biosphere Native Plants"

    render(conn, :about,
      page_title: title,
      meta_description:
        "Biosphere Native Plants is run by biologist and educator Dr. Shelley Ball, " <>
          "founder of Biosphere Environmental Education. Visit the nursery at 1107 " <>
          "Althorpe Road, Westport, Eastern Ontario.",
      canonical_path: ~p"/about",
      json_ld: StructuredData.business_page("AboutPage", "/about", title)
    )
  end

  @doc """
  Renders the home page. `ContactController` also calls this to re-show the
  home page's newsletter form with errors (`:newsletter_form`,
  `:newsletter_captcha_error`).
  """
  def render_home(conn, assigns \\ []) do
    newsletter_form =
      assigns[:newsletter_form] || Outreach.change_subscriber(%NewsletterSubscriber{})

    conn
    |> put_view(ShelleyPlantsWeb.PageHTML)
    |> render(:home,
      canonical_path: ~p"/",
      json_ld: StructuredData.home(),
      featured_plants: Catalog.list_featured_plants(6),
      turnstile_site_key: Turnstile.site_key(),
      newsletter_form: Phoenix.Component.to_form(newsletter_form),
      newsletter_captcha_error: assigns[:newsletter_captcha_error]
    )
  end
end
