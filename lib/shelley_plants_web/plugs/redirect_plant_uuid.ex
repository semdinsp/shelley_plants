defmodule ShelleyPlantsWeb.Plugs.RedirectPlantUuid do
  @moduledoc """
  Permanently redirects old plant URLs, which used the plant's UUID
  (/plants/0e61…), to the slug URL (/plants/aquilegia-canadensis), so
  existing links and search results keep working.

  Also covers /plants/:uuid/edit, and keeps any query string.
  """

  import Plug.Conn

  alias ShelleyPlants.Catalog.Plant
  alias ShelleyPlants.Repo

  def init(opts), do: opts

  def call(%Plug.Conn{path_info: ["plants", id | rest]} = conn, _opts)
      when rest in [[], ["edit"]] do
    with {:ok, uuid} <- Ecto.UUID.cast(id),
         %Plant{slug: slug} <- Repo.get(Plant, uuid) do
      path = Enum.join(["", "plants", slug | rest], "/")
      location = if conn.query_string == "", do: path, else: path <> "?" <> conn.query_string

      conn
      |> put_resp_header("location", location)
      |> send_resp(:moved_permanently, "")
      |> halt()
    else
      _ -> conn
    end
  end

  def call(conn, _opts), do: conn
end
