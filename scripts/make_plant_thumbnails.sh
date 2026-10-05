#!/usr/bin/env bash
# Generate small, sRGB gallery thumbnails for plant photos (macOS: uses sips).
#
#   scripts/make_plant_thumbnails.sh          # only photos without a thumbnail
#   scripts/make_plant_thumbnails.sh --force  # regenerate all
#
# Thumbnails are written to priv/static/images/plants/thumbs/<name>.jpg and
# picked up automatically by ShelleyPlantsWeb.PlantImages.thumb_url/1.
set -euo pipefail

src_dir="$(cd "$(dirname "$0")/.." && pwd)/priv/static/images/plants"
out_dir="$src_dir/thumbs"
srgb="/System/Library/ColorSync/Profiles/sRGB Profile.icc"
mkdir -p "$out_dir"

for src in "$src_dir"/*.{jpg,jpeg,png,webp,JPG,JPEG,PNG,WEBP}; do
  [ -f "$src" ] || continue
  name="$(basename "${src%.*}")"
  out="$out_dir/$name.jpg"
  if [ -f "$out" ] && [ "${1:-}" != "--force" ]; then continue; fi
  sips -s format jpeg -s formatOptions 65 -Z 640 -m "$srgb" "$src" --out "$out" >/dev/null
  echo "thumb: $name.jpg ($(($(stat -f%z "$out") / 1024)) KB)"
done
