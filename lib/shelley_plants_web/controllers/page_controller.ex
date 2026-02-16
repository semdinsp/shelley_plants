defmodule ShelleyPlantsWeb.PageController do
  use ShelleyPlantsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
