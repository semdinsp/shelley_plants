defmodule ShelleyPlantsWeb.GardenPlannerRedirectController do
  use ShelleyPlantsWeb, :controller

  @moduledoc """
  Redirects the old `/design-garden` URL to `/garden-planner` so existing
  links and bookmarks keep working after the rename.
  """

  def index(conn, _params) do
    redirect(conn, to: ~p"/garden-planner")
  end
end
