defmodule ShelleyPlantsWeb.ContactHTML do
  @moduledoc """
  The Contact Us page: contact form and newsletter signup.
  """
  use ShelleyPlantsWeb, :html

  embed_templates "contact_html/*"

  @doc """
  Hidden "honeypot" field. People never see it; bots that fill in every
  field do, and their submission is quietly dropped.
  """
  def honeypot(assigns) do
    ~H"""
    <div class="absolute -left-[9999px] w-px h-px overflow-hidden" aria-hidden="true">
      <label>
        Leave this field empty <input type="text" name="website" tabindex="-1" autocomplete="off" />
      </label>
    </div>
    """
  end

  attr :site_key, :string, required: true
  attr :error, :string, default: nil

  @doc "Cloudflare Turnstile widget plus any verification error."
  def turnstile(assigns) do
    ~H"""
    <div>
      <div class="cf-turnstile" data-sitekey={@site_key} data-theme="auto"></div>
      <p :if={@error} class="mt-1.5 flex gap-2 items-center text-sm text-error">
        <.icon name="hero-exclamation-circle" class="size-5" /> {@error}
      </p>
    </div>
    """
  end
end
