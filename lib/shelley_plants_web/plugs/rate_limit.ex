defmodule ShelleyPlantsWeb.Plugs.RateLimit do
  @moduledoc """
  Per-IP rate limit. Over the limit, responds 429 with a Retry-After header.

      plug ShelleyPlantsWeb.Plugs.RateLimit, bucket: :public_mcp

  The limit and window come from `config :shelley_plants, :rate_limits`,
  keyed by bucket (e.g. `public_mcp: [limit: 60, window_seconds: 60]`).
  """

  import Plug.Conn

  alias ShelleyPlants.RateLimiter
  alias ShelleyPlantsWeb.ClientIp

  @defaults [limit: 60, window_seconds: 60]

  def init(opts), do: Keyword.fetch!(opts, :bucket)

  def call(conn, bucket) do
    config =
      Keyword.merge(
        @defaults,
        Application.get_env(:shelley_plants, :rate_limits, [])[bucket] || []
      )

    case RateLimiter.hit(
           {bucket, ClientIp.from_conn(conn)},
           config[:limit],
           config[:window_seconds]
         ) do
      {:allow, _count} ->
        conn

      {:deny, retry_after} ->
        conn
        |> put_resp_header("retry-after", Integer.to_string(retry_after))
        |> put_resp_content_type("application/json")
        |> send_resp(
          429,
          Jason.encode!(%{error: "rate_limited", retry_after_seconds: retry_after})
        )
        |> halt()
    end
  end
end
