# Plant Data Entry Guide — New Fields for Garden Planner

Hi Shelley,

We've added five new data fields to each plant record to power the **Design Your Garden** tool. These fields are now available on the admin edit form for every plant.

The existing fields (height description, light description, moisture notes, etc.) are unchanged — they still appear on the website exactly as before. These new fields are used only for matching plants to a customer's garden design.

---

## The five new fields

### 1. Min height (cm) and Max height (cm)

**What it is:** The typical mature height range of the plant, in centimetres.

**Why we need it:** The current height field stores text like `"24–48""` (in inches). The garden planner needs clean numbers in centimetres to filter out plants that are too tall for a customer's space (e.g. if they have a low fence).

**How to fill it in:**
- Convert from inches: multiply by 2.54. Quick reference below.
- If the plant has a single height (e.g. Prairie Smoke at `12"`), set both min and max to the same value.
- Use the typical garden height, not the absolute maximum under ideal conditions.

**Inch → cm conversion guide:**

| Inches | cm |
|---|---|
| 4" | 10 |
| 6" | 15 |
| 12" | 30 |
| 18" | 46 |
| 24" | 61 |
| 36" | 91 |
| 48" | 122 |
| 60" | 152 |
| 72" | 183 |
| 84" | 213 |
| 96" | 244 |

**Examples:**
- Black-eyed Susan `12–36"` → Min: **30**, Max: **91**
- Big Bluestem `48–96"` → Min: **122**, Max: **244**
- Prairie Smoke `12"` → Min: **30**, Max: **30**
- Lance-leaved Heal All `4–12"` → Min: **10**, Max: **30**

---

### 2. Typical spread (cm)

**What it is:** How wide a single mature plant typically grows, in centimetres. This is the plant's diameter at ground level, not its canopy spread for trees.

**Why we need it:** This drives the quantity calculation — the garden planner divides the garden area by the spread of each plant to suggest how many to buy. A plant with a 30 cm spread needs roughly 4× as many plants per square metre as one with a 60 cm spread.

**How to fill it in:**
- Use the typical spread for a garden setting, not a wild or optimal setting.
- If you're unsure, a reasonable default for most perennials is **30–45 cm**. Grasses vary widely.
- For groundcovers (like Lance-leaved Heal All), use a smaller value like **15–20 cm**.
- For tall grasses and large plants (like Big Bluestem), use **45–60 cm**.

**Example rough guide:**

| Plant type | Typical spread |
|---|---|
| Low groundcover / small wildflower | 15–25 cm |
| Medium perennial wildflower | 30–45 cm |
| Large perennial / tall wildflower | 45–60 cm |
| Native grass (small) | 30–45 cm |
| Native grass (large, e.g. Big Bluestem) | 45–75 cm |
| Shrub | 60–150 cm |
| Tree | 100–300 cm+ |

---

### 3. Sun level

**What it is:** A single category describing the plant's light needs. Choose one:

| Option | What it means |
|---|---|
| **Full sun** | Needs 6 or more hours of direct sunlight per day |
| **Part shade** | Grows well in 3–6 hours of sun, or dappled shade |
| **Full shade** | Thrives in under 3 hours of direct sun |

**Why we need it:** The garden planner asks customers how much sun their space gets, then filters plants accordingly. The existing light requirements text field has too much variation (some entries are whole paragraphs) to be used for matching reliably.

**How to fill it in:** Pick the option that best describes the plant's *preference* or *requirement* — not just what it can tolerate. For example, if a plant "prefers full sun but tolerates part shade," choose **Full sun**.

**Examples:**
- Black-eyed Susan — Full sun
- Canada Columbine — Part shade
- Bottlebrush Grass — Full shade
- Wild Bergamot — Part shade (tolerates sun but does best with some shade)

---

### 4. Moisture level

**What it is:** A single category describing the plant's moisture needs. Choose one:

| Option | What it means |
|---|---|
| **Dry** | Tolerates or prefers dry, well-drained soil. Drought-hardy once established. |
| **Average** | Typical garden soil that doesn't waterlog or dry out completely. |
| **Moist** | Prefers consistently moist soil — good for rain gardens or near a pond edge. |
| **Wet** | Tolerates or requires boggy, wet, or periodically flooded soil. |

**Why we need it:** This will be used in a future version of the garden planner where customers can describe how wet or dry their site is. Adding it now means the data will be ready when we need it.

**How to fill it in:** Use the plant's natural preference. If the description says "average to dry," choose **Dry**. If it says "average to moist," choose **Moist**. If it's truly in the middle, choose **Average**.

**Examples:**
- Little Bluestem — Dry
- Wild Bergamot — Average
- Swamp Milkweed — Moist
- Cut-leaf Coneflower — Wet
- Great Blue Lobelia — Moist

---

## Where to enter this data

1. Log in to the site as admin
2. Go to **Species List** → click the **eye icon** on a plant → click **Edit plant**
3. Scroll to the new fields (they appear between Height and Light requirements)
4. Fill in the values and click **Save Plant**

The existing height text, light requirements text, and moisture description text are unchanged — just fill in the new fields alongside them.

---

## Priority order for data entry

The most important field for the garden planner to work well is **Sun level** — this is the primary filter. **Min/max height** is second. **Spread** is needed for quantities. **Moisture level** can come last as it will be used in a future update.

If you'd like, we can also prepare a spreadsheet with all 40 plants pre-filled with our best guesses, so you only need to review and correct rather than enter from scratch. Just ask.

---

## Current plant list (40 plants to update)

| Plant | Notes |
|---|---|
| Anise Hyssop | |
| Big Bluestem | Large grass — high spread value |
| Black-eyed Susan | |
| Bottlebrush Grass | Full shade |
| Canada Columbine | |
| Canada Wild Rye | |
| Common Sneezeweed | Wet moisture |
| Cut-leaf Coneflower | Full sun to full shade — use part shade |
| Downy Wood Mint | |
| False Yellow Sorghum | Full sun, dry |
| Foxglove Beardtongue | |
| Great Blue Lobelia | Moist |
| Grey-headed Coneflower | |
| Hair Wood Mint | Part shade |
| Hairy Beardtongue | |
| Lance-leaved Coreopsis | Full sun |
| Lance-leaved Heal All | Small groundcover |
| Little Bluestem | Full sun, dry |
| New England Aster | |
| Nodding Onion | |
| Obedient Plant | Moist |
| Pale Corydalis | |
| Pale Purple Coneflower | Full sun |
| Pearly Everlasting | |
| Prairie Coneflower | |
| Prairie Dropseed | Full sun, dry — small grass |
| Prairie Smoke | Short, full sun |
| Rough Blazing Star | Full sun |
| Showy Tick Trefoil | |
| Sky Blue Aster | |
| Smooth Blue Aster | |
| Spotted Bee Balm | Full sun |
| Spotted Joe Pye Weed | Tall — high min/max height |
| Swamp Milkweed | Moist |
| Tall Bellflower | Part/full shade, moist |
| 3-lobed Black-eyed Susan | |
| Upland White Goldenrod | Full sun |
| White Prairie Clover | Full sun, dry |
| Wild Bergamot | |
| Wild Lupine | Full sun |
| Yellow Giant Hyssop | |
