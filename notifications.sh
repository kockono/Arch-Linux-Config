#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: bash notifications.sh [--apply]   # preview or set Plasma notifications to the top right'
}
apply=false
if (($# > 1)); then usage >&2; exit 2; fi
case "${1:-}" in
  '') ;;
  --apply) apply=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

echo 'Notification plan: place Plasma notification popups at the top right instead of beside the tray widget; preserve panels and application preferences.'
if [[ $apply == false ]]; then exit 0; fi
command -v kwriteconfig6 >/dev/null || { echo 'Missing kwriteconfig6 (Plasma 6 required).' >&2; exit 1; }
config="$HOME/.config/plasmanotifyrc"
mkdir -p "$(dirname "$config")"
if [[ -f $config ]]; then
  backup=$(mktemp "$config.backup.XXXXXXXX")
  cp -p "$config" "$backup"
  printf 'Backup: %s\n' "$backup"
fi
kwriteconfig6 --file plasmanotifyrc --group Notifications --key PopupPosition --notify TopRight
echo 'Notification position saved. Check the next notification to confirm placement on your monitor layout.'
