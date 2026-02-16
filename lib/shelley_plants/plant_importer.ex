defmodule ShelleyPlants.PlantImporter do
  @moduledoc """
  Imports plants from a JSON file into the database.

  This module has no dependency on Mix and works in both dev (via the
  `mix plants.import` task) and in production releases on Fly.io:

      /app/bin/shelley_plants eval \\
        'ShelleyPlants.PlantImporter.run(["/tmp/plants_import.json"])'

  Records are validated through `ShelleyPlants.Catalog.Plant.changeset/2`
  and upserted on `latin_name`. The JSON format is documented in
  `plant_import_format.md`.
  """

  alias ShelleyPlants.Catalog.Plant
  alias ShelleyPlants.Repo

  @replaceable_fields ~w(
    common_name flower_color bloom_time height chelsea_chop
    light_requirements moisture plant_type native_ontario locally_native
    ecological_benefit deer_resistant notes picture updated_at
  )a

  @doc """
  Run the import. Accepts a one-element list so it can be called identically
  from the Mix task and from a release eval.

      ShelleyPlants.PlantImporter.run(["/path/to/plants.json"])
  """
  def run([path]) do
    {:ok, _} = Application.ensure_all_started(:shelley_plants)

    path = Path.expand(path)

    unless File.exists?(path) do
      log_error("File not found: #{path}")
      System.halt(1)
    end

    log_info("Reading #{path}…")

    records =
      case File.read!(path) |> Jason.decode() do
        {:ok, list} when is_list(list) ->
          list

        {:ok, _} ->
          log_error("JSON must be an array of objects.")
          System.halt(1)

        {:error, reason} ->
          log_error("Failed to parse JSON: #{inspect(reason)}")
          System.halt(1)
      end

    log_info("Found #{length(records)} record(s). Importing…\n")

    {ok_count, error_count} =
      records
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0}, fn {attrs, index}, {ok, err} ->
        case import_plant(attrs, index) do
          :ok -> {ok + 1, err}
          :error -> {ok, err + 1}
        end
      end)

    log_info("""

    ── Import complete ──────────────────────────────
      Succeeded : #{ok_count}
      Failed    : #{error_count}
      Total     : #{ok_count + error_count}
    ─────────────────────────────────────────────────
    """)

    if error_count > 0, do: System.halt(1)
  end

  def run(_) do
    log_error("Usage: ShelleyPlants.PlantImporter.run([\"/path/to/plants.json\"])")
    System.halt(1)
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp import_plant(attrs, index) when is_map(attrs) do
    latin_name = Map.get(attrs, "latin_name") || Map.get(attrs, :latin_name)
    label = "[#{index}] #{latin_name || "(no latin_name)"}"

    changeset = Plant.changeset(%Plant{}, stringify_keys(attrs))

    if changeset.valid? do
      upsert(changeset, label)
    else
      errors = format_errors(changeset)
      log_error("  FAIL  #{label}\n        #{errors}")
      :error
    end
  end

  defp import_plant(_attrs, index) do
    log_error("  FAIL  [#{index}] Record is not a JSON object — skipped.")
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
        log_info("  OK    #{label} (#{action})")
        :ok

      {:error, failed_changeset} ->
        errors = format_errors(failed_changeset)
        log_error("  FAIL  #{label}\n        #{errors}")
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

  defp log_info(msg), do: IO.puts(msg)
  defp log_error(msg), do: IO.puts(:stderr, msg)
end
