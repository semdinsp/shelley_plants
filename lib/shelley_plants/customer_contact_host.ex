defmodule ShelleyPlants.CustomerContactHost do
  @moduledoc """
  Tells the CustomerContact campaign-email library who can be emailed and how
  campaign emails should look.

  Recipients are the current newsletter subscribers. Unsubscribing from the
  newsletter deletes the subscriber (`ShelleyPlants.Outreach.unsubscribe/1`),
  so everyone returned here has opted in. Campaign unsubscribes, bounces and
  complaints go on the library's own suppression list.

  There are no app-side tags, so admins segment with the library's built-in
  tags on /admin/contact/audience.
  """

  @behaviour CustomerContact.Host

  import Ecto.Query

  alias CustomerContact.Recipient
  alias ShelleyPlants.EmailLayout
  alias ShelleyPlants.Outreach.NewsletterSubscriber
  alias ShelleyPlants.Repo

  @impl true
  def brand do
    sender = Application.fetch_env!(:shelley_plants, :mail_sender)
    site_url = EmailLayout.site_url()

    %{
      name: sender[:name],
      from: {sender[:name], sender[:address]},
      reply_to: sender[:reply_to],
      postal_address: "1107 Althorpe Road, Westport, ON K0G 1X0, Canada",
      website_url: site_url,
      logo_url: site_url <> "/images/biologo.jpg",
      # Matches ShelleyPlants.EmailLayout: dark green header, green links,
      # cream background
      primary_color: "#0c170d",
      accent_color: "#006017",
      background_color: "#f1ede3"
    }
  end

  @impl true
  def list_recipients do
    from(s in NewsletterSubscriber,
      order_by: [asc: s.inserted_at],
      select: %Recipient{ref: type(s.id, :string), email: s.email, name: s.name}
    )
    |> Repo.all()
  end
end
