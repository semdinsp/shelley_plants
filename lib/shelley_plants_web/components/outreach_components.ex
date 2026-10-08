defmodule ShelleyPlantsWeb.OutreachComponents do
  @moduledoc """
  Pieces shared by the public forms (contact page and home page): the
  newsletter signup form, the Cloudflare Turnstile bot check and the hidden
  honeypot field.
  """
  use Phoenix.Component
  use ShelleyPlantsWeb, :verified_routes

  import ShelleyPlantsWeb.CoreComponents

  @doc "Loads the Turnstile script. Include once on any page with a `turnstile/1`."
  def turnstile_script(assigns) do
    ~H"""
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer>
    </script>
    """
  end

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

  attr :action, :string,
    required: true,
    doc: "checked server-side, so one form's token can't be used on the other"

  attr :error, :string, default: nil

  @doc "Cloudflare Turnstile widget plus any verification error."
  def turnstile(assigns) do
    ~H"""
    <div>
      <div class="cf-turnstile" data-sitekey={@site_key} data-action={@action} data-theme="auto">
      </div>
      <p :if={@error} class="mt-1.5 flex gap-2 items-center text-sm text-error">
        <.icon name="hero-exclamation-circle" class="size-5" /> {@error}
      </p>
    </div>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :id, :string, required: true
  attr :site_key, :string, required: true
  attr :captcha_error, :string, default: nil

  attr :return_to, :string,
    default: nil,
    doc: ~s(where to send the visitor afterwards: "home" or the contact page)

  @doc "Newsletter signup form (name optional, email, bot check)."
  def newsletter_form(assigns) do
    ~H"""
    <.form :let={f} for={@form} id={@id} action={~p"/newsletter"} class="relative space-y-1">
      <.honeypot />
      <input :if={@return_to} type="hidden" name="return_to" value={@return_to} />
      <.input field={f[:name]} label="Name (optional)" autocomplete="name" />
      <.input field={f[:email]} type="email" label="Email" autocomplete="email" required />
      <div class="pt-2">
        <.turnstile site_key={@site_key} action="newsletter" error={@captcha_error} />
      </div>
      <div class="pt-4">
        <.button class="btn btn-primary w-full gap-2">
          <.icon name="hero-check" class="size-5" /> Sign me up
        </.button>
      </div>
    </.form>
    """
  end
end
