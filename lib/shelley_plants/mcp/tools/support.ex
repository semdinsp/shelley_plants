defmodule ShelleyPlants.MCP.Tools.Support do
  @moduledoc """
  Shared helpers for MCP plant tools: scope/admin checks and plant
  serialization to the JSON shape returned by every tool.
  """

  alias Anubis.Server.Response
  alias ShelleyPlants.Accounts.Scope
  alias ShelleyPlants.Catalog.Plant

  @doc """
  Requires the current MCP token to carry `scope` ("read" or "write").

  Returns `:ok` or `{:error, message}`, for use directly in a `with` chain
  alongside `require_admin_scope/1` and context calls.
  """
  def require_scope(frame, scope) do
    if scope in Map.get(frame.assigns, :mcp_scopes, []) do
      :ok
    else
      {:error, "This token does not have \"#{scope}\" access."}
    end
  end

  @doc """
  Builds an admin `Scope` for the token's owning user, or an error if the
  user is not an admin (matches `ShelleyPlants.Catalog`'s write rules).
  """
  def require_admin_scope(frame) do
    case Map.get(frame.assigns, :current_user) do
      %{is_admin: true} = user -> {:ok, Scope.for_user(user)}
      _ -> {:error, "Only an admin user's token can make changes to the plant catalog."}
    end
  end

  def error_reply(message, frame) do
    {:reply, Response.error(Response.tool(), message), frame}
  end

  def json_reply(data, frame) do
    {:reply, Response.json(Response.tool(), data), frame}
  end

  def changeset_error_reply(changeset, frame) do
    message =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
      |> Enum.map_join("; ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)

    error_reply(message, frame)
  end

  @doc """
  Serializes a `%Plant{}` to the map every tool returns.
  """
  def plant_json(%Plant{} = plant) do
    %{
      id: plant.id,
      common_name: plant.common_name,
      latin_name: plant.latin_name,
      flower_color: plant.flower_color,
      bloom_time: plant.bloom_time,
      height: plant.height,
      chelsea_chop: plant.chelsea_chop,
      light_requirements: plant.light_requirements,
      moisture: plant.moisture,
      plant_type: plant.plant_type,
      native_ontario: plant.native_ontario,
      locally_native: plant.locally_native,
      ecological_benefit: plant.ecological_benefit,
      deer_resistant: plant.deer_resistant,
      notes: plant.notes,
      category: plant.category,
      height_min_cm: plant.height_min_cm,
      height_max_cm: plant.height_max_cm,
      spread_cm: plant.spread_cm,
      sun_level: plant.sun_level,
      moisture_level: plant.moisture_level,
      moisture_unacceptable: plant.moisture_unacceptable,
      picture: plant.picture
    }
  end
end
