defmodule ShelleyPlants.Accounts.UserNotifier do
  import Swoosh.Email

  alias ShelleyPlants.Mailer
  alias ShelleyPlants.Accounts.User

  require EEx
  require Logger

  @site_name "Biosphere Native Plants"

  # Delivers the email using the application mailer. Every email is sent as
  # both HTML (branded layout below) and plain text.
  defp deliver(recipient, subject, content) do
    sender = Application.fetch_env!(:shelley_plants, :mail_sender)

    email =
      new()
      |> to(recipient)
      |> from({sender[:name], sender[:address]})
      |> reply_to(sender[:reply_to])
      |> subject(subject)
      |> html_body(render_html(content))
      |> text_body(render_text(content))

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        {:ok, email}

      {:error, reason} ->
        Logger.error("Failed to deliver email to #{recipient}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Confirm your new email address", %{
      preheader: "Confirm the change to your #{@site_name} email address.",
      heading: "Confirm your new email",
      greeting: "Hi #{user.email},",
      body:
        "We received a request to change the email address on your account. " <>
          "Click the button below to confirm the change.",
      button: "Confirm email change",
      url: url,
      expiry: "This link expires in 7 days.",
      ignore: "If you didn't request this change, you can safely ignore this email."
    })
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Your #{@site_name} login link", %{
      preheader: "Your login link for #{@site_name}.",
      heading: "Log in to your account",
      greeting: "Hi #{user.email},",
      body: "Click the button below to log in to #{@site_name}. No password needed.",
      button: "Log in",
      url: url,
      expiry: "This link expires in 15 minutes and can only be used once.",
      ignore: "If you didn't request this email, you can safely ignore it."
    })
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Welcome to #{@site_name} — confirm your account", %{
      preheader: "Confirm your email to finish setting up your account.",
      heading: "Welcome to #{@site_name}",
      greeting: "Hi #{user.email},",
      body:
        "Thanks for signing up! Click the button below to confirm your email " <>
          "address and log in.",
      button: "Confirm my account",
      url: url,
      expiry: "This link expires in 15 minutes and can only be used once.",
      ignore: "If you didn't create an account with us, you can safely ignore this email."
    })
  end

  # ── Rendering ───────────────────────────────────────────────────────────────

  defp render_text(c) do
    """
    #{c.heading}

    #{c.greeting}

    #{c.body}

    #{c.url}

    #{c.expiry}
    #{c.ignore}

    --
    #{@site_name}
    Ontario native wildflowers and grasses
    #{site_url()}
    """
  end

  defp render_html(content) do
    content
    |> Map.merge(%{site_name: @site_name, site_url: site_url(), logo_url: logo_url()})
    |> email_html()
    |> Phoenix.HTML.safe_to_string()
  end

  # Public site URL for links and images in emails (email clients need
  # absolute URLs). Built from the endpoint's :url config so it works even
  # when the endpoint isn't running. Dev overrides it with :email_site_url
  # so test emails link to (and load the logo from) production.
  defp site_url do
    Application.get_env(:shelley_plants, :email_site_url) ||
      endpoint_url(Application.get_env(:shelley_plants, ShelleyPlantsWeb.Endpoint)[:url])
  end

  defp endpoint_url(url_config) do
    scheme = Keyword.get(url_config, :scheme, "http")
    host = Keyword.get(url_config, :host, "localhost")

    case Keyword.get(url_config, :port) do
      port when port in [nil, 80, 443] -> "#{scheme}://#{host}"
      port -> "#{scheme}://#{host}:#{port}"
    end
  end

  defp logo_url, do: site_url() <> "/images/biologo.jpg"

  # Table-based layout with inline styles, which is what email clients
  # (Gmail, Outlook, Apple Mail) render reliably. Colours are the site's
  # light theme in hex, since email clients don't support oklch.
  EEx.function_from_string(
    :defp,
    :email_html,
    ~S"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta name="color-scheme" content="light">
      <title><%= @heading %></title>
      <style>
        @media only screen and (max-width: 480px) {
          .content { padding-left: 24px !important; padding-right: 24px !important; }
        }
      </style>
    </head>
    <body style="margin:0;padding:0;background-color:#f1ede3;">
      <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:#f1ede3;"><%= @preheader %></div>
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#f1ede3;">
        <tr>
          <td align="center" style="padding:32px 16px;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;background-color:#ffffff;border-radius:12px;overflow:hidden;">
              <%!-- Header --%>
              <tr>
                <td align="center" style="background-color:#0c170d;padding:28px 24px 22px;">
                  <a href="<%= @site_url %>" style="text-decoration:none;">
                    <img src="<%= @logo_url %>" width="80" height="78" alt="<%= @site_name %>" style="display:block;border:0;width:80px;height:78px;border-radius:50%;">
                  </a>
                  <p style="margin:14px 0 0;font-family:Georgia,'Times New Roman',serif;font-size:20px;font-weight:bold;color:#fbfaf6;letter-spacing:0.3px;"><%= @site_name %></p>
                </td>
              </tr>
              <tr>
                <td style="background-color:#cd8800;height:4px;line-height:4px;font-size:0;">&nbsp;</td>
              </tr>
              <%!-- Body --%>
              <tr>
                <td class="content" style="padding:36px 40px 12px;font-family:Helvetica,Arial,sans-serif;color:#0d140b;">
                  <h1 style="margin:0 0 20px;font-family:Georgia,'Times New Roman',serif;font-size:24px;line-height:1.3;font-weight:bold;color:#006017;"><%= @heading %></h1>
                  <p style="margin:0 0 14px;font-size:16px;line-height:1.6;"><%= @greeting %></p>
                  <p style="margin:0 0 28px;font-size:16px;line-height:1.6;"><%= @body %></p>
                  <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 auto 28px;">
                    <tr>
                      <td align="center" style="background-color:#006017;border-radius:8px;">
                        <a href="<%= @url %>" style="display:inline-block;padding:14px 32px;font-family:Helvetica,Arial,sans-serif;font-size:16px;font-weight:bold;color:#ffffff;text-decoration:none;border-radius:8px;"><%= @button %></a>
                      </td>
                    </tr>
                  </table>
                  <p style="margin:0 0 6px;font-size:13px;line-height:1.5;color:#5b6358;">Button not working? Copy and paste this link into your browser:</p>
                  <p style="margin:0 0 24px;font-size:13px;line-height:1.5;word-break:break-all;"><a href="<%= @url %>" style="color:#006017;"><%= @url %></a></p>
                  <p style="margin:0 0 6px;font-size:13px;line-height:1.5;color:#5b6358;"><%= @expiry %></p>
                  <p style="margin:0 0 24px;font-size:13px;line-height:1.5;color:#5b6358;"><%= @ignore %></p>
                </td>
              </tr>
              <%!-- Footer --%>
              <tr>
                <td class="content" align="center" style="padding:20px 40px 28px;border-top:1px solid #e7e2d6;font-family:Helvetica,Arial,sans-serif;font-size:13px;line-height:1.6;color:#85603c;">
                  <strong><%= @site_name %></strong><br>
                  Ontario native wildflowers and grasses<br>
                  <a href="<%= @site_url %>" style="color:#006017;text-decoration:none;"><%= String.replace(@site_url, ~r{^https?://}, "") %></a><br>
                  <span style="color:#8a8f86;">Questions? Just reply to this email.</span>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """,
    [:assigns],
    engine: Phoenix.HTML.Engine
  )
end
