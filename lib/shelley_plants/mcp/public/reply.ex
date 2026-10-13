defmodule ShelleyPlants.MCP.Public.Reply do
  @moduledoc false
  # Tool replies for the public server (kept separate from the admin
  # server's ShelleyPlants.MCP.Tools.Support).

  alias Anubis.Server.Response

  def json(data, frame), do: {:reply, Response.json(Response.tool(), data), frame}
  def error(message, frame), do: {:reply, Response.error(Response.tool(), message), frame}

  def result({:ok, data}, frame), do: json(data, frame)
  def result({:error, message}, frame) when is_binary(message), do: error(message, frame)
end
