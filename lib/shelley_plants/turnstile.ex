defmodule ShelleyPlants.Turnstile do
  @moduledoc """
  Server-side verification of Cloudflare Turnstile tokens, the bot check on
  the public contact and newsletter forms.

  The widget on the page adds a `cf-turnstile-response` token to the form;
  `verify/3` checks it with Cloudflare. Config (`:turnstile`, set in
  `config/runtime.exs`):

    * `:site_key` / `:secret_key` — `TURNSTILE_SITE_KEY` / `TURNSTILE_SECRET_KEY`
    * `:hostnames` — `TURNSTILE_HOSTNAMES`, the site's domains. When set, a
      token must come from one of them and carry the form's expected action.
      Left empty outside prod, since Cloudflare's test keys return a dummy
      hostname and action.
  """

  require Logger

  @verify_url "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  @max_token_length 2048

  def site_key, do: config(:site_key)

  @doc """
  Returns `:ok` if Cloudflare accepts the token for `action` (the widget's
  `data-action`), `{:error, reason}` otherwise.
  """
  def verify(token, action, remote_ip \\ nil)

  def verify(token, action, remote_ip)
      when is_binary(token) and token != "" and byte_size(token) <= @max_token_length do
    case config(:secret_key) do
      secret when is_binary(secret) and secret != "" ->
        token |> request(secret, remote_ip) |> check(action)

      _ ->
        Logger.error("TURNSTILE_SECRET_KEY is not set; rejecting form submission")
        {:error, :not_configured}
    end
  end

  def verify(_token, _action, _remote_ip), do: {:error, :invalid_token}

  defp request(token, secret, remote_ip) do
    form = [secret: secret, response: token] ++ if(remote_ip, do: [remoteip: remote_ip], else: [])

    case Req.post(
           @verify_url,
           [form: form, retry: false, receive_timeout: 10_000] ++ req_options()
         ) do
      {:ok, %Req.Response{status: 200, body: %{} = body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        Logger.error("Turnstile siteverify returned HTTP #{status}")
        {:error, :unavailable}

      {:error, reason} ->
        Logger.error("Turnstile siteverify request failed: #{inspect(reason)}")
        {:error, :unavailable}
    end
  end

  defp check({:error, _} = error, _action), do: error

  defp check({:ok, %{"success" => true} = body}, action) do
    case config(:hostnames) || [] do
      [] ->
        :ok

      hostnames ->
        if body["hostname"] in hostnames and body["action"] == action do
          :ok
        else
          Logger.info(
            "Turnstile token for the wrong site or form: " <>
              "hostname=#{inspect(body["hostname"])} action=#{inspect(body["action"])}"
          )

          {:error, :rejected}
        end
    end
  end

  defp check({:ok, body}, _action) do
    Logger.info("Turnstile rejected a submission: #{inspect(body["error-codes"])}")
    {:error, :rejected}
  end

  defp config(key), do: Application.get_env(:shelley_plants, :turnstile, [])[key]

  # Lets tests stub Cloudflare with Req.Test.
  defp req_options, do: Application.get_env(:shelley_plants, :turnstile_req_options, [])
end
