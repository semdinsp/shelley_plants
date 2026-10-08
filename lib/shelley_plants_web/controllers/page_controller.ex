defmodule ShelleyPlantsWeb.PageController do
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.{Catalog, Outreach, Turnstile}
  alias ShelleyPlants.Outreach.NewsletterSubscriber

  def home(conn, _params) do
    render_home(conn)
  end

  def about(conn, _params) do
    render(conn, :about, page_title: "About")
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
      featured_plants: Catalog.list_featured_plants(6),
      turnstile_site_key: Turnstile.site_key(),
      newsletter_form: Phoenix.Component.to_form(newsletter_form),
      newsletter_captcha_error: assigns[:newsletter_captcha_error]
    )
  end
end
