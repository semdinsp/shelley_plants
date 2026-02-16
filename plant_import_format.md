# Plant Import — JSON Format Reference

Use this document when asking Claude (or another AI) to convert plant data from an email, spreadsheet, or other source into the correct JSON format for `mix plants.import`.

---

## Instructions for Claude

Convert the plant data below into a valid JSON array. Each plant must be a JSON object following the field definitions in this document. Output **only** the JSON array — no explanation, no markdown fences, no extra text.

Rules:
- `latin_name` is the unique key. If a plant already exists with the same `latin_name`, it will be updated.
- `plant_type` must be exactly `"perennial"` or `"annual"`.
- Boolean fields must be `true` or `false` (not strings like `"yes"`).
- Optional fields (`ecological_benefit`, `notes`, `picture`) may be omitted or set to `null`.
- All required string fields must be non-empty strings.

---

## Field Reference

| Field | Type | Required | Allowed values / notes |
|---|---|---|---|
| `common_name` | string | **yes** | Common English name, e.g. `"Purple Coneflower"` |
| `latin_name` | string | **yes** | Scientific name (unique key), e.g. `"Echinacea purpurea"` |
| `plant_type` | string | **yes** | `"perennial"` or `"annual"` only |
| `flower_color` | string | **yes** | Descriptive colour, e.g. `"purple-pink"` |
| `bloom_time` | string | **yes** | Season or months, e.g. `"July–September"` |
| `height` | string | **yes** | Height range, e.g. `"60–120 cm"` |
| `light_requirements` | string | **yes** | e.g. `"Full sun"`, `"Part shade"`, `"Full sun to part shade"` |
| `moisture` | string | **yes** | e.g. `"Medium"`, `"Dry to medium"`, `"Medium to wet"` |
| `chelsea_chop` | boolean | **yes** | `true` if plant benefits from the Chelsea Chop pruning technique |
| `native_ontario` | boolean | **yes** | `true` if native to Ontario |
| `locally_native` | boolean | **yes** | `true` if locally native to the immediate region |
| `deer_resistant` | boolean | **yes** | `true` if the plant is deer resistant |
| `ecological_benefit` | string | no | Description of ecological value, e.g. `"Host plant for monarch butterfly"` |
| `notes` | string | no | Any additional growing tips or observations |
| `picture` | string | no | URL or file path to an image |

---

## Example JSON Output

```json
[
  {
    "common_name": "Purple Coneflower",
    "latin_name": "Echinacea purpurea",
    "plant_type": "perennial",
    "flower_color": "purple-pink",
    "bloom_time": "July–September",
    "height": "60–120 cm",
    "light_requirements": "Full sun to part shade",
    "moisture": "Dry to medium",
    "chelsea_chop": false,
    "native_ontario": true,
    "locally_native": true,
    "deer_resistant": true,
    "ecological_benefit": "Attracts bees, butterflies, and goldfinches; host plant for several moth species",
    "notes": "Drought tolerant once established. Self-seeds freely.",
    "picture": null
  },
  {
    "common_name": "Wild Bergamot",
    "latin_name": "Monarda fistulosa",
    "plant_type": "perennial",
    "flower_color": "lavender-pink",
    "bloom_time": "July–August",
    "height": "60–90 cm",
    "light_requirements": "Full sun to part shade",
    "moisture": "Dry to medium",
    "chelsea_chop": true,
    "native_ontario": true,
    "locally_native": true,
    "deer_resistant": true,
    "ecological_benefit": "Important nectar source for native bees and hummingbirds",
    "notes": null,
    "picture": null
  }
]
```

---

## Prompt Template

Copy and paste the following into a new Claude conversation, then paste the raw email or plant list after it:

---

> Convert the following plant data into a JSON array for import into a native plants database.
> Follow the format defined in the Field Reference below exactly.
> Output only the raw JSON array — no explanation, no markdown fences.
>
> **Field Reference:**
>
> | Field | Type | Required | Notes |
> |---|---|---|---|
> | `common_name` | string | yes | Common English name |
> | `latin_name` | string | yes | Scientific name (unique key) |
> | `plant_type` | string | yes | `"perennial"` or `"annual"` only |
> | `flower_color` | string | yes | Descriptive colour |
> | `bloom_time` | string | yes | Season or months |
> | `height` | string | yes | Height range, include units (cm or m) |
> | `light_requirements` | string | yes | Full sun / Part shade / etc. |
> | `moisture` | string | yes | Dry / Medium / Wet, may combine with "to" |
> | `chelsea_chop` | boolean | yes | true or false |
> | `native_ontario` | boolean | yes | true or false |
> | `locally_native` | boolean | yes | true or false |
> | `deer_resistant` | boolean | yes | true or false |
> | `ecological_benefit` | string | no | Omit if unknown |
> | `notes` | string | no | Omit if none |
> | `picture` | string | no | Omit if none |
>
> **Plant data:**
>
> [PASTE PLANT DATA HERE]

---

## Running the Import

```bash
# Dry run — validate the file manually first
cat plants.json | python3 -m json.tool

# Import
mix plants.import plants.json
```

The task logs each record individually:

```
  OK    [1] Echinacea purpurea (INSERTED)
  OK    [2] Monarda fistulosa (UPDATED)
  FAIL  [3] (no latin_name)
        common_name: can't be blank | latin_name: can't be blank

── Import complete ──────────────────────────────
  Succeeded : 2
  Failed    : 1
  Total     : 3
─────────────────────────────────────────────────
```

Failed records do **not** halt the import — all records are attempted and the task exits with code `1` if any failures occurred.
