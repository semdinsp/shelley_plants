defmodule Mix.Tasks.Plants.Import do
  @shortdoc "Import plants from a JSON file into the database"

  @moduledoc """
  Imports plant records from a JSON file into the plants table.

  Records are validated through the `ShelleyPlants.Catalog.Plant` changeset.
  Existing records are upserted by `latin_name` (the unique key). If a plant
  with the same `latin_name` already exists, all other fields will be updated.

  ## Usage

      mix plants.import PATH_TO_FILE.json

  ## Exit codes

  - `0` — all records were imported successfully (or upserted).
  - `1` — one or more records failed validation or database insertion.

  ## JSON format

  The file must contain a JSON array of objects. See `plant_import_format.md`
  for the full field reference.

  ## Example

      mix plants.import priv/data/plants.json
  """

  use Mix.Task

  alias ShelleyPlants.Catalog.Plant
  alias ShelleyPlants.Repo

  @replaceable_fields ~w(
    common_name flower_color bloom_time height chelsea_chop
    light_requirements moisture plant_type native_ontario locally_native
    ecological_benefit deer_resistant notes picture updated_at
  )a

  @impl Mix.Task
  def run([path]) do
    Mix.Task.run("app.start")

    path = Path.expand(path)

    unless File.exists?(path) do
      Mix.shell().error("File not found: #{path}")
      System.halt(1)
    end

    Mix.shell().info("Reading #{path}…")

    records =
      case File.read!(path) |> Jason.decode() do
        {:ok, list} when is_list(list) ->
          list

        {:ok, _} ->
          Mix.shell().error("JSON must be an array of objects.")
          System.halt(1)

        {:error, reason} ->
          Mix.shell().error("Failed to parse JSON: #{inspect(reason)}")
          System.halt(1)
      end

    Mix.shell().info("Found #{length(records)} record(s). Importing…\n")

    {ok_count, error_count} =
      records
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0}, fn {attrs, index}, {ok, err} ->
        case import_plant(attrs, index) do
          :ok -> {ok + 1, err}
          :error -> {ok, err + 1}
        end
      end)

    Mix.shell().info("""

    ── Import complete ──────────────────────────────
      Succeeded : #{ok_count}
      Failed    : #{error_count}
      Total     : #{ok_count + error_count}
    ─────────────────────────────────────────────────
    """)

    if error_count > 0, do: System.halt(1)
  end

  def run(_) do
    Mix.shell().error("""
    Usage: mix plants.import PATH_TO_FILE.json
    """)

    System.halt(1)
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp import_plant(attrs, index) when is_map(attrs) do
    latin_name = Map.get(attrs, "latin_name") || Map.get(attrs, :latin_name)
    label = "[#{index}] #{latin_name || "(no latin_name)"}"

    # Validate through the changeset first (without hitting the DB)
    changeset = Plant.changeset(%Plant{}, stringify_keys(attrs))

    if changeset.valid? do
      upsert(changeset, label)
    else
      errors = format_errors(changeset)
      Mix.shell().error("  FAIL  #{label}\n        #{errors}")
      :error
    end
  end

  defp import_plant(_attrs, index) do
    Mix.shell().error("  FAIL  [#{index}] Record is not a JSON object — skipped.")
    :error
  end

  defp upsert(changeset, label) do
    result =
      Repo.insert(
        changeset,
        on_conflict: {:replace, @replaceable_fields},
        conflict_target: :latin_name
      )

    case result do
      {:ok, plant} ->
        action = if plant.__meta__.state == :loaded, do: "UPDATED", else: "INSERTED"
        Mix.shell().info("  OK    #{label} (#{action})")
        :ok

      {:error, failed_changeset} ->
        errors = format_errors(failed_changeset)
        Mix.shell().error("  FAIL  #{label}\n        #{errors}")
        :error
    end
  end

  defp stringify_keys(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
    |> Enum.join(" | ")
  end
end
