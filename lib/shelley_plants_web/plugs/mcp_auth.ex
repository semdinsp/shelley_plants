defmodule ShelleyPlantsWeb.Plugs.McpAuth do
  @moduledoc """
  Authenticates MCP requests via a bearer token from the settings page.

  On success, assigns `:current_user` and `:mcp_scopes` (a list of granted
  scope strings, e.g. `["read"]` or `["read", "write"]`) on the conn. These
  flow through to `frame.assigns` inside every MCP tool call, since
  `Anubis.Server.Transport.StreamableHTTP.Plug` inherits `conn.assigns` into
  the request context.
  """

  import Plug.Conn

  alias ShelleyPlants.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- extract_bearer_token(conn),
         {:ok, user, mcp_token} <- Accounts.get_user_by_mcp_token(token) do
      conn
      |> assign(:current_user, user)
      |> assign(:mcp_scopes, mcp_token.scopes)
    else
      _ -> unauthorized(conn)
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" -> {:ok, token}
      _ -> :error
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "unauthorized"}))
    |> halt()
  end
end
