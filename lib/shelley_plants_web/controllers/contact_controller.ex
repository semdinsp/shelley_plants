defmodule ShelleyPlantsWeb.ContactController do
  use ShelleyPlantsWeb, :controller

  alias ShelleyPlants.{Outreach, Turnstile}
  alias ShelleyPlants.Outreach.{ContactMessage, NewsletterSubscriber}

  @captcha_error "Please complete the verification check and try again."

  def show(conn, _params) do
    render_page(conn)
  end

  def create_message(conn, %{"contact_message" => params} = all_params) do
    cond do
      bot?(all_params) ->
        message_sent(conn)

      verified?(conn, all_params, "contact") ->
        case Outreach.submit_contact_message(params) do
          {:ok, _message} ->
            message_sent(conn)

          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity) |> render_page(contact_form: changeset)
        end

      true ->
        conn
        |> put_status(:unprocessable_entity)
        |> render_page(
          contact_form: Outreach.change_contact_message(%ContactMessage{}, params),
          contact_captcha_error: @captcha_error
        )
    end
  end

  def subscribe(conn, %{"newsletter_subscriber" => params} = all_params) do
    home? = all_params["return_to"] == "home"

    cond do
      bot?(all_params) ->
        subscribed(conn, home?)

      verified?(conn, all_params, "newsletter") ->
        case Outreach.subscribe(params) do
          {:error, changeset} ->
            subscribe_failed(conn, home?, newsletter_form: changeset)

          # Same response for new and existing subscribers, so the form
          # doesn't reveal who is on the list.
          _ok_or_existing ->
            subscribed(conn, home?)
        end

      true ->
        subscribe_failed(conn, home?,
          newsletter_form: Outreach.change_subscriber(%NewsletterSubscriber{}, params),
          newsletter_captcha_error: @captcha_error
        )
    end
  end

  # Re-show the form (with errors) on the page it was submitted from.
  defp subscribe_failed(conn, home?, assigns) do
    conn = put_status(conn, :unprocessable_entity)

    if home?,
      do: ShelleyPlantsWeb.PageController.render_home(conn, assigns),
      else: render_page(conn, assigns)
  end

  defp message_sent(conn) do
    conn
    |> put_flash(:info, "Thank you for your message! We'll get back to you soon.")
    |> redirect(to: ~p"/contact")
  end

  defp subscribed(conn, home?) do
    conn
    |> put_flash(:info, "You're signed up! Check your inbox for a welcome email.")
    |> redirect(to: if(home?, do: ~p"/" <> "#newsletter", else: ~p"/contact"))
  end

  defp render_page(conn, assigns \\ []) do
    render(conn, :show,
      page_title: "Contact Us",
      turnstile_site_key: Turnstile.site_key(),
      contact_form:
        Phoenix.Component.to_form(
          assigns[:contact_form] || Outreach.change_contact_message(%ContactMessage{})
        ),
      newsletter_form:
        Phoenix.Component.to_form(
          assigns[:newsletter_form] || Outreach.change_subscriber(%NewsletterSubscriber{})
        ),
      contact_captcha_error: assigns[:contact_captcha_error],
      newsletter_captcha_error: assigns[:newsletter_captcha_error]
    )
  end

  defp bot?(params), do: params["website"] not in [nil, ""]

  defp verified?(conn, params, action) do
    Turnstile.verify(params["cf-turnstile-response"], action, client_ip(conn)) == :ok
  end

  # Fly's proxy passes the visitor's IP in Fly-Client-IP.
  defp client_ip(conn) do
    case get_req_header(conn, "fly-client-ip") do
      [ip | _] -> ip
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end
