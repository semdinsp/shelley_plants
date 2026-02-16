# Shelley's Native Plants — Style Guide

A design system inspired by Ontario's natural landscape: forest greens, warm earth tones, golden wildflowers, and clean, botanical typography.

---

## Colour Palette

The palette uses two DaisyUI themes (`light` and `dark`) defined in `assets/css/app.css` using OKLCH colour values. Always use semantic colour tokens (DaisyUI classes or CSS variables) rather than hardcoded Tailwind colour utilities.

### Light Theme (default)

| Token | Role | OKLCH | Visual |
|---|---|---|---|
| `base-100` | Page background | `oklch(98.5% 0.005 90)` | Warm cream white |
| `base-200` | Card / section background | `oklch(95% 0.008 90)` | Soft beige |
| `base-300` | Borders, dividers | `oklch(90% 0.012 90)` | Beige |
| `base-content` | Body text | `oklch(18% 0.02 140)` | Deep forest dark |
| `primary` | Primary actions, links | `oklch(42% 0.14 148)` | Rich forest green |
| `primary-content` | Text on primary | `oklch(97% 0.02 148)` | Near white |
| `secondary` | Secondary actions | `oklch(52% 0.07 65)` | Warm earth brown |
| `secondary-content` | Text on secondary | `oklch(97% 0.01 65)` | Near white |
| `accent` | Highlights, badges | `oklch(68% 0.15 75)` | Goldenrod |
| `accent-content` | Text on accent | `oklch(18% 0.04 75)` | Dark |
| `neutral` | Subtle backgrounds | `oklch(40% 0.03 60)` | Bark / soil |
| `neutral-content` | Text on neutral | `oklch(97% 0 0)` | White |

### Dark Theme (system preference or manual toggle)

| Token | Role | OKLCH | Visual |
|---|---|---|---|
| `base-100` | Page background | `oklch(19% 0.025 148)` | Deep forest night |
| `base-200` | Card / section background | `oklch(15% 0.02 148)` | Darker forest |
| `base-300` | Borders, dividers | `oklch(12% 0.015 148)` | Deepest forest |
| `base-content` | Body text | `oklch(93% 0.018 148)` | Soft green-white |
| `primary` | Primary actions, links | `oklch(60% 0.15 148)` | Lighter forest green |
| `accent` | Highlights, badges | `oklch(72% 0.16 75)` | Bright goldenrod |

Semantic colours (info, success, warning, error) are consistent across both themes.

### Usage Rules

- Use `btn-primary` for the main call-to-action on each page.
- Use `btn-secondary` or `btn-outline` for secondary actions.
- Use `btn-accent` sparingly for special highlights.
- Use `bg-base-200` for card and section backgrounds.
- Use `text-base-content` (default) for all body text; `text-base-content/70` for muted text.
- Avoid hardcoded Tailwind colour utilities (e.g. `text-green-700`) in new components. Exception: hero sections may use Tailwind utilities for the background gradient where semantic tokens are insufficient.

---

## Typography

Defined in `assets/css/app.css` via `@theme` and `@layer base`.

### Typefaces

| Font | Weight(s) | Usage |
|---|---|---|
| **Lora** (serif) | 400, 600, 700, 400 italic | H1, H2, H3 headings |
| **Inter** (sans-serif) | 400, 500, 600, 700 | Body text, UI labels, navigation |

Both fonts are loaded from Google Fonts. The `font-serif` Tailwind utility applies Lora; `font-sans` applies Inter.

### Scale

Use Tailwind's default type scale. Recommended sizes:

| Element | Class(es) |
|---|---|
| Hero heading | `text-4xl sm:text-6xl font-bold` |
| Section heading | `text-3xl font-bold` |
| Sub-heading / card title | `text-lg font-semibold` |
| Body text | `text-base` (default) |
| Small / caption | `text-sm` |
| Eyebrow / label | `text-sm font-semibold uppercase tracking-widest` |

### Heading contrast

H1–H3 elements receive Lora automatically via `@layer base`. On gradient hero backgrounds, always add explicit text colour classes to ensure contrast:

```html
<h1 class="... text-stone-900 dark:text-stone-100">…</h1>
<p class="... text-stone-700 dark:text-stone-300">…</p>
```

---

## Layout

- Max content width: `max-w-5xl` for full-width sections; `max-w-2xl` for single-column prose.
- Horizontal padding: `px-6 lg:px-8` on section containers.
- Vertical rhythm: `py-20` for major sections; `py-12` for secondary sections.
- Cards / feature blocks: `rounded-2xl bg-base-200 p-6`
- Credential / list cards: `rounded-xl bg-base-200 p-4`

---

## Components

### Buttons

```html
<!-- Primary CTA -->
<a class="btn btn-primary btn-lg gap-2">Browse the Plant Catalog</a>

<!-- Secondary / outline -->
<a class="btn btn-outline btn-lg gap-2">About Shelley</a>

<!-- Small inline action -->
<.link class="btn btn-ghost btn-sm">Plants</.link>
```

### Cards

```html
<div class="p-6 rounded-2xl bg-base-200">
  <h3 class="font-semibold text-lg mb-2">Card Title</h3>
  <p class="text-sm text-base-content/70 leading-6">Card body text.</p>
</div>
```

### Eyebrow / section label

```html
<p class="text-sm font-semibold uppercase tracking-widest text-primary mb-3">
  Section Label
</p>
```

### Navigation (root layout)

The site navbar is defined in `lib/shelley_plants_web/components/layouts/root.html.heex`. It uses DaisyUI `navbar`, `menu`, and `btn` classes with the ecological primary colour for the Log in button.

---

## Icons

Heroicons (via `@plugin "../vendor/heroicons"`) are available as `hero-*` classes:

```html
<.icon name="hero-sparkles" class="size-5 text-primary" />
```

Use `text-primary` for brand-coloured icons, `text-base-content/60` for muted icons.

---

## Dark / Light Mode

Theme switching is handled client-side via `localStorage` and the `data-theme` attribute on `<html>`. The toggle is available in the navbar (theme_toggle component in `layouts.ex`).

- Prefer semantic colour tokens that adapt automatically.
- When using Tailwind utilities that don't adapt (e.g. `from-green-50`), always add `dark:` variants.

---

## File Locations

| File | Purpose |
|---|---|
| `assets/css/app.css` | Theme tokens, font imports, base styles |
| `lib/shelley_plants_web/components/layouts/root.html.heex` | Root HTML shell, site navbar |
| `lib/shelley_plants_web/components/layouts.ex` | `Layouts.app` component (inner page wrapper), flash group, theme toggle |
| `lib/shelley_plants_web/controllers/page_html/home.html.heex` | Landing page |
