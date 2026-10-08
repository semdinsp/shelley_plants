defmodule ShelleyPlants.Turnstile do
  @moduledoc """
  Server-side verification of Cloudflare Turnstile tokens, the bot check on
  the public contact and newsletter forms.

  The widget on the page adds a `cf-turnstile-response` token to the form;
  `verify/2` checks it with Cloudflare. Keys come from the `:turnstile`
  config (`TURNSTILE_SITE_KEY` / `TURNSTILE_SECRET_KEY`).
  """

  require Logger

  @verify_url "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  def site_key, do: config(:site_key)

  @doc "Returns `:ok` if Cloudflare accepts the token, `{:error, reason}` otherwise."
  def verify(token, remote_ip \\ nil)

  def verify(token, remote_ip) when is_binary(token) and token != "" do
    case config(:secret_key) do
      secret when is_binary(secret) and secret != "" -> request(secret, token, remote_ip)
      _ -> missing_secret()
    end
  end

  def verify(_token, _remote_ip), do: {:error, :missing_token}

  defp request(secret, token, remote_ip) do
    form = [secret: secret, response: token] ++ if(remote_ip, do: [remoteip: remote_ip], else: [])

    case Req.post(@verify_url, [form: form, retry: false] ++ req_options()) do
      {:ok, %Req.Response{status: 200, body: %{"success" => true}}} ->
        :ok

      {:ok, %Req.Response{body: body}} ->
        Logger.info("Turnstile rejected a submission: #{inspect(body)}")
        {:error, :rejected}

      {:error, reason} ->
        Logger.error("Turnstile verification request failed: #{inspect(reason)}")
        {:error, :unavailable}
    end
  end

  defp missing_secret do
    Logger.error("TURNSTILE_SECRET_KEY is not set; rejecting form submission")
    {:error, :not_configured}
  end

  defp config(key), do: Application.get_env(:shelley_plants, :turnstile, [])[key]

  # Lets tests stub Cloudflare with Req.Test.
  defp req_options, do: Application.get_env(:shelley_plants, :turnstile_req_options, [])
end
