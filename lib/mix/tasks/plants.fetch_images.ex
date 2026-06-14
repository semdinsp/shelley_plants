defmodule Mix.Tasks.Plants.FetchImages do
  @moduledoc """
  Finds a photo on Wikimedia Commons for each plant that doesn't have one
  yet, downloads it into `priv/static/images/plants/`, and records the
  `picture` path both in the database and in `priv/static/plants/plants.json`
  (under the matching `latin_name`) so the same paths can be applied in
  production via `ShelleyPlants.PlantImporter`.

      mix plants.fetch_images

  Only plants with `picture == nil` are processed. Re-running is safe —
  plants that already have a picture are skipped.
  """
  use Mix.Task

  import Ecto.Query

  alias ShelleyPlants.Catalog.Plant
  alias ShelleyPlants.Repo

  @shortdoc "Fetch missing plant photos from Wikimedia Commons"

  @commons_api "https://commons.wikimedia.org/w/api.php"
  @image_dir "priv/static/images/plants"
  @json_path "priv/static/plants/plants.json"
  @allowed_mimes ~w(image/jpeg image/png)
  @user_agent "ShelleyPlants/1.0 (https://shelley-plants.fly.dev; scott.sproule@gmail.com)"
  @request_delay_ms 1_000

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    plants = Repo.all(from p in Plant, where: is_nil(p.picture))

    Mix.shell().info("Found #{length(plants)} plant(s) without a picture.\n")

    File.mkdir_p!(@image_dir)

    updates =
      Enum.reduce(plants, %{}, fn plant, acc ->
        Process.sleep(@request_delay_ms)

        case fetch_and_save(plant) do
          {:ok, picture_path} ->
            update_plant(plant, picture_path)
            Mix.shell().info("  OK    #{plant.latin_name} -> #{picture_path}")
            Map.put(acc, plant.latin_name, picture_path)

          {:error, reason} ->
            Mix.shell().error("  FAIL  #{plant.latin_name}: #{reason}")
            acc
        end
      end)

    if map_size(updates) > 0 do
      update_json(updates)
      Mix.shell().info("\nUpdated #{map_size(updates)} entr(y/ies) in #{@json_path}")
    end
  end

  defp fetch_and_save(plant) do
    search_name = strip_parenthetical(plant.latin_name)

    with {:ok, image} <- search_image(search_name),
         {:ok, body} <- download(image.url) do
      ext = ext_for_mime(image.mime)
      filename = slug(search_name) <> ext
      dest = Path.join(@image_dir, filename)
      File.write!(dest, body)
      {:ok, "/images/plants/#{filename}"}
    end
  end

  defp search_image(latin_name) do
    case Req.get(@commons_api,
           headers: [{"user-agent", @user_agent}],
           params: [
             action: "query",
             generator: "search",
             gsrnamespace: 6,
             gsrsearch: latin_name,
             gsrlimit: 10,
             prop: "imageinfo",
             iiprop: "url|mime",
             format: "json"
           ]
         ) do
      {:ok, %{status: 200, body: body}} -> find_candidate(body, latin_name)
      {:ok, %{status: status}} -> {:error, "search failed with status #{status}"}
      {:error, reason} -> {:error, "search failed: #{inspect(reason)}"}
    end
  end

  defp find_candidate(body, latin_name) do
    pages = get_in(body, ["query", "pages"]) || %{}

    candidates =
      pages
      |> Map.values()
      |> Enum.flat_map(fn page ->
        case page["imageinfo"] do
          [%{"url" => url, "mime" => mime}] when mime in @allowed_mimes ->
            [%{url: url, mime: mime, title: page["title"]}]

          _ ->
            []
        end
      end)

    case Enum.find(candidates, &title_matches?(&1.title, latin_name)) || List.first(candidates) do
      nil -> {:error, "no matching image found on Wikimedia Commons"}
      image -> {:ok, image}
    end
  end

  defp title_matches?(title, latin_name) do
    [genus, species | _] = String.split(latin_name)
    title = String.downcase(title)

    String.contains?(title, String.downcase(genus)) and
      String.contains?(title, String.downcase(species))
  end

  defp download(url) do
    case Req.get(url, headers: [{"user-agent", @user_agent}]) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, "download failed with status #{status}"}
      {:error, reason} -> {:error, "download failed: #{inspect(reason)}"}
    end
  end

  defp ext_for_mime("image/jpeg"), do: ".jpg"
  defp ext_for_mime("image/png"), do: ".png"

  defp strip_parenthetical(latin_name) do
    latin_name |> String.replace(~r/\s*\([^)]*\)/, "") |> String.trim()
  end

  defp slug(latin_name) do
    latin_name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end

  defp update_plant(plant, picture_path) do
    plant
    |> Plant.changeset(%{"picture" => picture_path})
    |> Repo.update!()
  end

  defp update_json(updates) do
    records =
      @json_path
      |> File.read!()
      |> Jason.decode!()
      |> Enum.map(fn record ->
        case Map.fetch(updates, record["latin_name"]) do
          {:ok, picture_path} -> Map.put(record, "picture", picture_path)
          :error -> record
        end
      end)

    File.write!(@json_path, Jason.encode!(records, pretty: true))
  end
end
