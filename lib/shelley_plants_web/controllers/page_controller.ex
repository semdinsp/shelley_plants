defmodule ShelleyPlantsWeb.PageController do
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.Catalog

  def home(conn, _params) do
    featured_plants = Catalog.list_featured_plants(6)
    render(conn, :home, featured_plants: featured_plants)
  end

  def about(conn, _params) do
    render(conn, :about)
  end
end
