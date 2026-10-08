defmodule ShelleyPlants.EmailLayout do
  @moduledoc """
  Builds and delivers branded site emails (HTML + plain text).

  Content is a map with:

    * `:subject`, `:preheader`, `:heading`, `:greeting` — required
    * `:paragraphs` — list of body paragraphs
    * `:details` — optional list of `{label, value}` rows, e.g. a submitted
      form; values keep their line breaks
    * `:button` and `:url` — optional call-to-action button
    * `:footnotes` — optional list of small print lines
    * `:unsubscribe_url` — optional; adds an Unsubscribe link to the footer
      and `List-Unsubscribe` headers so mail apps can offer one-click
      unsubscribe

  Everything interpolated into the HTML is escaped, so user-submitted text is
  safe to include.
  """

  import Swoosh.Email

  alias ShelleyPlants.Mailer

  require EEx
  require Logger

  @site_name "Biosphere Native Plants"

  @defaults %{
    paragraphs: [],
    details: [],
    button: nil,
    url: nil,
    footnotes: [],
    unsubscribe_url: nil
  }

  def site_name, do: @site_name

  @doc """
  Builds an email with the site's sender and branded layout.

  Options: `:to` (required), `:bcc`, `:reply_to` (defaults to the configured
  sender reply-to).
  """
  def build(content, opts) do
    sender = Application.fetch_env!(:shelley_plants, :mail_sender)
    content = Map.merge(@defaults, content)

    new()
    |> to(Keyword.fetch!(opts, :to))
    |> bcc(List.wrap(opts[:bcc]))
    |> from({sender[:name], sender[:address]})
    |> reply_to(opts[:reply_to] || sender[:reply_to])
    |> subject(content.subject)
    |> html_body(render_html(content))
    |> text_body(render_text(content))
    |> put_unsubscribe_headers(content.unsubscribe_url)
  end

  # RFC 8058 one-click unsubscribe: mail apps POST to the URL directly.
  defp put_unsubscribe_headers(email, nil), do: email

  defp put_unsubscribe_headers(email, url) do
    email
    |> header("List-Unsubscribe", "<#{url}>")
    |> header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
  end

  @doc "Delivers an email, logging (and returning) any delivery error."
  def deliver(%Swoosh.Email{} = email) do
    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        {:ok, email}

      {:error, reason} ->
        Logger.error("Failed to deliver email to #{inspect(email.to)}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── Rendering ───────────────────────────────────────────────────────────────

  defp render_text(c) do
    details = Enum.map_join(c.details, "\n\n", fn {label, value} -> "#{label}:\n#{value}" end)

    [
      c.heading,
      c.greeting,
      Enum.join(c.paragraphs, "\n\n"),
      details,
      c.url,
      Enum.join(c.footnotes, "\n"),
      "--\n#{@site_name}\nOntario native wildflowers and grasses\n#{site_url()}\n",
      c.unsubscribe_url && "Unsubscribe: #{c.unsubscribe_url}\n"
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n\n")
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
  def site_url do
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
                  <%= for paragraph <- @paragraphs do %>
                  <p style="margin:0 0 14px;font-size:16px;line-height:1.6;"><%= paragraph %></p>
                  <% end %>
                  <%= if @details != [] do %>
                  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:14px 0 24px;background-color:#f7f5ef;border-radius:8px;">
                    <%= for {label, value} <- @details do %>
                    <tr>
                      <td style="padding:14px 18px 0;font-size:12px;font-weight:bold;letter-spacing:0.5px;text-transform:uppercase;color:#85603c;"><%= label %></td>
                    </tr>
                    <tr>
                      <td style="padding:4px 18px 14px;font-size:15px;line-height:1.6;white-space:pre-wrap;word-break:break-word;"><%= value %></td>
                    </tr>
                    <% end %>
                  </table>
                  <% end %>
                  <%= if @url do %>
                  <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:14px auto 28px;">
                    <tr>
                      <td align="center" style="background-color:#006017;border-radius:8px;">
                        <a href="<%= @url %>" style="display:inline-block;padding:14px 32px;font-family:Helvetica,Arial,sans-serif;font-size:16px;font-weight:bold;color:#ffffff;text-decoration:none;border-radius:8px;"><%= @button %></a>
                      </td>
                    </tr>
                  </table>
                  <p style="margin:0 0 6px;font-size:13px;line-height:1.5;color:#5b6358;">Button not working? Copy and paste this link into your browser:</p>
                  <p style="margin:0 0 24px;font-size:13px;line-height:1.5;word-break:break-all;"><a href="<%= @url %>" style="color:#006017;"><%= @url %></a></p>
                  <% end %>
                  <%= for footnote <- @footnotes do %>
                  <p style="margin:0 0 6px;font-size:13px;line-height:1.5;color:#5b6358;"><%= footnote %></p>
                  <% end %>
                  <div style="height:18px;line-height:18px;font-size:0;">&nbsp;</div>
                </td>
              </tr>
              <%!-- Footer --%>
              <tr>
                <td class="content" align="center" style="padding:20px 40px 28px;border-top:1px solid #e7e2d6;font-family:Helvetica,Arial,sans-serif;font-size:13px;line-height:1.6;color:#85603c;">
                  <strong><%= @site_name %></strong><br>
                  Ontario native wildflowers and grasses<br>
                  <a href="<%= @site_url %>" style="color:#006017;text-decoration:none;"><%= String.replace(@site_url, ~r{^https?://}, "") %></a><br>
                  <span style="color:#8a8f86;">Questions? Just reply to this email.</span>
                  <%= if @unsubscribe_url do %>
                  <br><a href="<%= @unsubscribe_url %>" style="color:#8a8f86;text-decoration:underline;">Unsubscribe</a>
                  <% end %>
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
