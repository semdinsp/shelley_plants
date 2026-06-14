defmodule Mix.Tasks.Plants.ConvertCsv do
  @moduledoc """
  Converts the plant database CSV export into the JSON format expected by
  `ShelleyPlants.PlantImporter`.

      mix plants.convert_csv priv/static/plants/Native\\ Plant\\ Database\\ For\\ Website_2026.csv priv/static/plants/plants.json

  CSV columns (in order):

      Common Name, Scientific Name, Flower Colour, Bloom Time, Height, Light,
      Moisture, Chelsea Chop?, Perennial/Annual, Ontario native?,
      Locally Native?, Deer Resistant?, Ecological Benefit, Additional information
  """
  use Mix.Task

  @shortdoc "Convert the plant CSV export into PlantImporter JSON"

  @impl Mix.Task
  def run([csv_path, json_path]) do
    rows =
      csv_path
      |> File.read!()
      |> parse_csv()

    [_header | data_rows] = rows

    existing_pictures = load_existing_pictures(json_path)

    records =
      data_rows
      |> Enum.map(&row_to_plant/1)
      |> Enum.reject(&(&1["common_name"] == "" and &1["latin_name"] == ""))
      |> Enum.map(fn record ->
        case Map.fetch(existing_pictures, record["latin_name"]) do
          {:ok, picture} -> Map.put(record, "picture", picture)
          :error -> record
        end
      end)

    File.write!(json_path, Jason.encode!(records, pretty: true))

    Mix.shell().info("Wrote #{length(records)} records to #{json_path}")
  end

  def run(_), do: Mix.raise("Usage: mix plants.convert_csv <input.csv> <output.json>")

  defp load_existing_pictures(json_path) do
    case File.read(json_path) do
      {:ok, content} ->
        content
        |> Jason.decode!()
        |> Map.new(fn record -> {record["latin_name"], record["picture"]} end)
        |> Map.reject(fn {_latin_name, picture} -> is_nil(picture) end)

      {:error, _} ->
        %{}
    end
  end

  defp row_to_plant([
         common_name,
         latin_name,
         flower_color,
         bloom_time,
         height,
         light,
         moisture,
         chelsea_chop,
         plant_type,
         native_ontario,
         locally_native,
         deer_resistant,
         ecological_benefit,
         notes
       ]) do
    %{
      "common_name" => normalize_whitespace(common_name),
      "latin_name" => normalize_whitespace(latin_name),
      "flower_color" => trim(flower_color),
      "bloom_time" => trim(bloom_time),
      "height" => trim(height),
      "light_requirements" => trim(light),
      "moisture" => trim(moisture),
      "chelsea_chop" => to_bool(chelsea_chop),
      "plant_type" => to_plant_type(plant_type),
      "native_ontario" => to_bool(native_ontario),
      "locally_native" => to_bool(locally_native),
      "deer_resistant" => to_bool(deer_resistant),
      "ecological_benefit" => blank_to_nil(ecological_benefit),
      "notes" => blank_to_nil(notes)
    }
  end

  defp trim(value), do: String.trim(value)

  defp normalize_whitespace(value) do
    value |> String.trim() |> String.replace(~r/\s+/, " ")
  end

  defp blank_to_nil(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp to_bool(value) do
    case value |> String.trim() |> String.downcase() do
      "yes" -> true
      "y" -> true
      "true" -> true
      _ -> false
    end
  end

  defp to_plant_type(value) do
    case value |> String.trim() |> String.downcase() do
      "annual" -> "annual"
      _ -> "perennial"
    end
  end

  # Minimal RFC4180 CSV parser: handles quoted fields, embedded commas,
  # embedded newlines, and escaped quotes ("").
  defp parse_csv(content) do
    content
    |> String.to_charlist()
    |> do_parse([], [], [])
  end

  defp do_parse([], field, row, rows) do
    row = Enum.reverse([field_to_string(field) | row])
    rows = [row | rows]
    Enum.reverse(rows) |> Enum.reject(&(&1 == [""]))
  end

  defp do_parse(chars, field, row, rows) do
    case chars do
      [?" | rest] ->
        {field_chars, rest} = parse_quoted(rest, [])
        do_parse(rest, field_chars ++ field, row, rows)

      [?, | rest] ->
        row = [field_to_string(field) | row]
        do_parse(rest, [], row, rows)

      [?\r, ?\n | rest] ->
        finish_row(rest, field, row, rows)

      [?\n | rest] ->
        finish_row(rest, field, row, rows)

      [c | rest] ->
        do_parse(rest, [c | field], row, rows)
    end
  end

  defp finish_row(rest, field, row, rows) do
    row = Enum.reverse([field_to_string(field) | row])
    do_parse(rest, [], [], [row | rows])
  end

  defp field_to_string(field), do: field |> Enum.reverse() |> List.to_string()

  defp parse_quoted([?", ?" | rest], acc), do: parse_quoted(rest, [?" | acc])
  defp parse_quoted([?" | rest], acc), do: {acc, rest}
  defp parse_quoted([c | rest], acc), do: parse_quoted(rest, [c | acc])
  defp parse_quoted([], acc), do: {acc, []}
end
