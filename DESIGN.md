# Shelley's Native Plants — Design Reference

This document describes the visual design of the site so that tweaks can be discussed and applied consistently.

---

## Design Philosophy

The aesthetic is inspired by Ontario's natural landscape — botanical illustration meets modern web. It aims to feel calm, earthy, and authoritative without being heavy.

- **Light mode** is the default, using warm cream backgrounds and rich forest green.
- **Dark mode** uses deep forest tones and is triggered automatically by the OS or via the theme toggle in the navigation bar.
- All colours, spacing, and shape values live in `assets/css/app.css` and are managed through the **daisyUI** theme system. Changing a value there cascades across the entire site.

---

## Colour Palette

The palette uses the OKLCH colour space, which gives perceptually consistent brightness across hues.

### Light Mode (default)

| Role | Name | OKLCH Value | Approximate colour |
|---|---|---|---|
| Page background | `base-100` | `oklch(98.5% 0.005 90)` | Warm off-white / cream |
| Subtle surface | `base-200` | `oklch(95% 0.008 90)` | Light warm grey |
| Borders / dividers | `base-300` | `oklch(90% 0.012 90)` | Warm mid-grey |
| Body text | `base-content` | `oklch(18% 0.02 140)` | Near-black with a green tint |
| **Primary** | Forest green | `oklch(42% 0.14 148)` | Deep forest green |
| Primary text on primary | `primary-content` | `oklch(97% 0.02 148)` | Near-white |
| **Secondary** | Earth brown | `oklch(52% 0.07 65)` | Warm bark brown |
| **Accent** | Goldenrod | `oklch(68% 0.15 75)` | Golden yellow-orange |
| Neutral | Soil / bark | `oklch(40% 0.03 60)` | Dark warm grey-brown |

### Dark Mode

| Role | Name | OKLCH Value | Approximate colour |
|---|---|---|---|
| Page background | `base-100` | `oklch(19% 0.025 148)` | Deep forest night |
| Subtle surface | `base-200` | `oklch(15% 0.02 148)` | Darker forest |
| Borders / dividers | `base-300` | `oklch(12% 0.015 148)` | Very dark green-black |
| Body text | `base-content` | `oklch(93% 0.018 148)` | Warm near-white |
| **Primary** | Lighter forest green | `oklch(60% 0.15 148)` | Mid forest green |
| **Accent** | Bright goldenrod | `oklch(72% 0.16 75)` | Vivid golden yellow |

### Semantic Colours (both modes)

| Role | Light | Dark | Usage |
|---|---|---|---|
| Info | `oklch(58% 0.15 240)` | same | Informational messages |
| Success | `oklch(58% 0.14 155)` | `oklch(60% 0.14 155)` | Confirmation / success toasts |
| Warning | `oklch(66% 0.16 70)` | same | Warnings |
| Error | `oklch(55% 0.22 20)` | `oklch(58% 0.22 20)` | Errors / destructive actions |

**To change a colour:** edit the corresponding `--color-*` line in `assets/css/app.css` under the appropriate `@plugin "../vendor/daisyui-theme"` block (there are two — one for `light`, one for `dark`).

---

## Typography

| Role | Font | Weight(s) | Notes |
|---|---|---|---|
| Body / UI | **Inter** | 400, 500, 600, 700 | Clean sans-serif; used for all body text, labels, buttons |
| Headings (h1–h3) | **Lora** | 400, 600, 700 (+ italic) | Elegant serif; evokes botanical/scientific print |

Both fonts are loaded from Google Fonts in `assets/css/app.css`.

**Heading sizes in use:**

| Element | Class | Approx size |
|---|---|---|
| Hero h1 | `text-5xl` / `sm:text-7xl` | 48px / 72px |
| Section h2 | `text-3xl` / `sm:text-4xl` | 30px / 36px |
| Card/component h3 | `text-base` | 16px |
| Page sub-header | `text-lg` | 18px |
| Nav items (desktop) | `text-base` (16px) | Bumped from default `btn-sm` |
| Nav items (mobile) | default menu size | ~14–15px |
| Labels / captions | `text-xs` with `uppercase tracking-[0.2em]` | Spaced small caps style |

---

## Shape & Spacing

These are defined as CSS variables and control all rounded corners site-wide:

| Token | Value | Used on |
|---|---|---|
| `--radius-selector` | `0.5rem` (8px) | Buttons, checkboxes, toggles |
| `--radius-field` | `0.5rem` (8px) | Inputs, selects |
| `--radius-box` | `0.75rem` (12px) | Cards, dropdown menus |
| `--border` | `1px` | All borders |

---

## Buttons

Buttons use [daisyUI](https://daisyui.com/components/button/) classes. The site uses three button styles:

### Primary button
Filled forest green. Used for the main call-to-action on a page.
```
class="btn btn-primary"
```
- Large variant (hero CTAs): add `btn-lg`
- Small variant (nav Log in): no extra modifier (default size)

### Ghost button
Transparent with hover highlight. Used for secondary actions and nav links.
```
class="btn btn-ghost"
```
- Nav links use `btn btn-ghost` (desktop, `text-base`)
- Hero secondary CTAs use `btn btn-ghost btn-lg`

### Soft primary button (default for internal actions)
Lightly tinted version of primary. Used for admin/form submit buttons.
```
class="btn btn-primary btn-soft"
```

### Icon buttons
Icons are added inside the button tag using the `<.icon>` component. The icon sits to the left of the text:
```heex
<.link class="btn btn-ghost">
  <.icon name="hero-photo" class="size-5" /> Visual Tour
</.link>
```

**Nav icon mapping:**

| Page | Icon |
|---|---|
| Plants | `hero-squares-2x2` |
| Visual Tour | `hero-photo` |
| About | `hero-information-circle` |
| Admin | `hero-cog-6-tooth` |
| Settings | `hero-user-circle` |
| Log in / Log out | `hero-arrow-right-on-rectangle` |

---

## Navigation

### Desktop (≥ 768px / `md` breakpoint)
- Sticky header, `max-w-5xl` centred, `h-14`
- Left: leaf SVG icon + "Shelley's Native Plants" text (font-semibold)
- Right: nav links as ghost buttons (`text-base`) + theme toggle
- Frosted glass effect: `bg-base-100/80 backdrop-blur-md`

### Mobile (< 768px)
- Same header, but site name text is hidden
- Right: hamburger icon (`hero-bars-3`) triggers a daisyUI dropdown
- Dropdown menu (`w-52`) shows icon + text for each link
- Theme toggle appears at the bottom of the dropdown

---

## Page Layout

All pages use a centred content container:
- Max width: `max-w-5xl` (1024px) — matches the header width
- Horizontal padding: `px-4 sm:px-6 lg:px-8`
- Vertical padding: `py-12`

The home page sections break out of this container at full viewport width (hero gradient, stats bar, about section background) but keep their inner content within `max-w-5xl`.

---

## Key Components

### Plant table (`/plants`)
- Full-width within the content container
- Thumbnail photo column (48×48px, rounded, `object-cover`)
- Row click navigates to the plant detail page
- Action column uses icon-only links: `hero-eye` for View

### Plant gallery (`/plants/gallery`)
- Grid of plant cards with photos

### Flash / toast messages
- Positioned bottom-right, auto-dismissed
- Uses semantic colours (success = green, error = red)

---

## Where to Make Changes

| What you want to change | Where to edit |
|---|---|
| Any colour (primary, background, text, etc.) | `assets/css/app.css` — `@plugin "../vendor/daisyui-theme"` blocks |
| Fonts | `assets/css/app.css` — `@import url(...)` and `@theme { --font-* }` |
| Header / navigation | `lib/shelley_plants_web/components/layouts/root.html.heex` |
| Page content width | `lib/shelley_plants_web/components/layouts.ex` — `max-w-5xl` in `app/1` |
| Button styles | daisyUI classes on each button (`btn-primary`, `btn-ghost`, etc.) |
| Home page content | `lib/shelley_plants_web/controllers/page_html/home.html.heex` |
| Plant list page | `lib/shelley_plants_web/live/plant_live/index.ex` |
| Plant detail page | `lib/shelley_plants_web/live/plant_live/show.ex` |
