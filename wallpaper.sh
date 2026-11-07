#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: bash wallpaper.sh [--apply]   # preview or install Smart Video Wallpaper Reborn for Plasma 6'
}
apply=false
if (($# > 1)); then usage >&2; exit 2; fi
case "${1:-}" in
  '') ;;
  --apply) apply=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

echo 'Wallpaper plan: install Smart Video Wallpaper Reborn 2.16.0 for the current user; keep the current desktop and lock-screen backgrounds unchanged.'
if [[ $apply == false ]]; then exit 0; fi
for tool in kpackagetool6 pacman curl sha256sum; do
  command -v "$tool" >/dev/null || { echo "Missing required command: $tool" >&2; exit 1; }
done
plugin=luisbocanegra.smart.video.wallpaper.reborn
if kpackagetool6 --type Plasma/Wallpaper --show "$plugin" >/dev/null 2>&1; then
  echo 'Smart Video Wallpaper Reborn is already installed; keeping the existing version.'
  exit 0
fi
pacman -Q qt6-multimedia qt6-multimedia-ffmpeg >/dev/null 2>&1 || {
  echo 'Install the playback dependencies first: sudo pacman -S --needed qt6-multimedia qt6-multimedia-ffmpeg' >&2
  exit 1
}

stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
archive="$stage/wallpaper.tar.gz"
curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' \
  'https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/releases/download/v2.16.0/plasma-smart-video-wallpaper-reborn-v2.16.0.tar.gz' \
  --output "$archive"
# Pinned from the official release asset; upstream publishes no separate checksum file.
printf '4f144fbe6b29b2aaad173ce9c989c411f59463e520daf9fd59b3211bfdc7b7c2  %s\n' "$archive" | sha256sum --check --strict
kpackagetool6 --type Plasma/Wallpaper --install "$archive"
kpackagetool6 --type Plasma/Wallpaper --show "$plugin"
echo 'Installed. Right-click the desktop > Desktop and Wallpaper > Wallpaper type > Smart Video Wallpaper Reborn, add a local video, then Apply.'
