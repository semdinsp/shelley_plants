defmodule ShelleyPlantsWeb.ContactHTML do
  @moduledoc """
  The Contact Us page: contact form and newsletter signup.
  """
  use ShelleyPlantsWeb, :html

  import ShelleyPlantsWeb.OutreachComponents

  embed_templates "contact_html/*"
end
