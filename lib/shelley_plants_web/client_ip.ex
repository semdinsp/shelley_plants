defmodule ShelleyPlantsWeb.ClientIp do
  @moduledoc """
  The visitor's IP address. On Fly, the proxy passes it in the
  Fly-Client-IP header; locally it's the socket's remote IP.
  """

  def from_conn(%Plug.Conn{} = conn) do
    case Plug.Conn.get_req_header(conn, "fly-client-ip") do
      [ip | _] -> ip
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end
