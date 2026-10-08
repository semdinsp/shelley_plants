defmodule ShelleyPlantsWeb.UnsubscribeController do
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.Outreach

  # Opening the link only shows a confirmation button: email security
  # scanners follow links automatically, and must not unsubscribe anyone.
  def show(conn, %{"token" => token}) do
    case Outreach.subscriber_for_unsubscribe_token(token) do
      {:ok, nil} -> render_page(conn, :done)
      {:ok, subscriber} -> render_page(conn, :confirm, email: subscriber.email, token: token)
      {:error, :invalid} -> conn |> put_status(:not_found) |> render_page(:invalid)
    end
  end

  # Handles both the confirmation button and one-click unsubscribes from
  # mail apps (List-Unsubscribe-Post).
  def create(conn, %{"token" => token}) do
    case Outreach.unsubscribe(token) do
      :ok -> render_page(conn, :done)
      {:error, :invalid} -> conn |> put_status(:not_found) |> render_page(:invalid)
    end
  end

  defp render_page(conn, state, assigns \\ []) do
    render(conn, :show, [page_title: "Unsubscribe", state: state] ++ assigns)
  end
end
