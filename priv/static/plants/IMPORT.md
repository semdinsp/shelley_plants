# Importing Plants from the Spreadsheet

This describes how to take the plant database spreadsheet and load it into
the `plants` table, both locally and in production on Fly.io.

## 1. Export the spreadsheet as CSV

Export the spreadsheet (e.g. Google Sheets: File > Download > CSV) and save
it to `priv/static/plants/Native Plant Database For Website_2026.csv`,
overwriting the existing file.

The CSV must have these columns, in this order:

```
Common Name, Scientific Name, Flower Colour, Bloom Time, Height, Light,
Moisture, Chelsea Chop?, Perennial/Annual, Ontario native?,
Locally Native?, Deer Resistant?, Ecological Benefit, Additional information
```

Boolean columns (`Chelsea Chop?`, `Ontario native?`, `Locally Native?`,
`Deer Resistant?`) use `Yes` / anything else (treated as `No`).
`Perennial/Annual` must say `Annual` for annuals — anything else is treated
as `Perennial`.

Rows with both `Common Name` and `Scientific Name` blank are skipped (e.g.
trailing empty rows).

## 2. Convert CSV to JSON

```bash
mix plants.convert_csv "priv/static/plants/Native Plant Database For Website_2026.csv" priv/static/plants/plants.json
```

This writes `priv/static/plants/plants.json` in the format expected by
`ShelleyPlants.PlantImporter`.

## 3. Import locally

```bash
mix run -e 'ShelleyPlants.PlantImporter.run(["priv/static/plants/plants.json"])'
```

Records are validated through `ShelleyPlants.Catalog.Plant.changeset/2` and
upserted on `latin_name` — existing plants are updated, new ones are
inserted. Safe to re-run.

## 4. Import in production (Fly.io)

The importer runs via the release binary, no `mix` required.

### a. Copy the JSON file to the running machine

```bash
fly sftp shell -a shelley-plants
```

Inside the SFTP shell:

```
put priv/static/plants/plants.json /tmp/plants_import.json
```

Then exit the shell (`exit` or Ctrl-D).

### b. Run the importer

```bash
fly ssh console -a shelley-plants -C '/app/bin/shelley_plants eval "ShelleyPlants.PlantImporter.run([\"/tmp/plants_import.json\"])"'
```

Check the output for `Succeeded` / `Failed` counts. As with local imports,
this is an upsert keyed on `latin_name`, so it's safe to re-run after
updating the spreadsheet — just repeat steps 1-4.

## 5. Fetch plant photos

For any plant without a `picture`, `mix plants.fetch_images` searches
[Wikimedia Commons](https://commons.wikimedia.org/) for a matching photo by
latin name, downloads it into `priv/static/images/plants/`, and records the
`/images/plants/<file>` path both on the plant record in the database and in
`priv/static/plants/plants.json`.

```bash
mix plants.fetch_images
```

- Only plants with `picture == nil` are processed — safe to re-run, it skips
  anything that already has a photo.
- `mix plants.convert_csv` preserves existing `picture` values in
  `plants.json` when regenerating it from the CSV, so re-running step 2 after
  fetching images won't lose them.
- If a plant fails with "no matching image found", check the latin name for
  typos/synonyms (this happened with a misspelled species name in the source
  spreadsheet) and re-run after fixing it.

### Local

Just run the command above — it updates the dev database directly and
downloads images into `priv/static/images/plants/`.

### Production (Fly.io)

The image files need to ship as part of a deploy (they're committed to the
repo under `priv/static/images/plants/`), and the `picture` paths need to be
set on the production database records.

1. Commit the new image files and the updated `plants.json`.
2. Deploy as normal (`fly deploy`) so the image files are present in
   `priv/static/images/plants/` on the release.
3. Copy `plants.json` to the machine and run the importer (steps 4a/4b
   above) — the upsert will set `picture` on each plant from the JSON.

There's no need to run `plants.fetch_images` itself in production — it only
needs to run once locally to find the images and commit them.
