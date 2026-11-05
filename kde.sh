#!/usr/bin/env bash
set -euo pipefail

apply=false
case "${1:-}" in
  '') ;;
  --apply) apply=true ;;
  -h|--help)
    echo 'Usage: bash kde.sh [--apply]   # preview or opt in to KDE changes'
    exit 0 ;;
  *) echo 'Usage: bash kde.sh [--apply]' >&2; exit 2 ;;
esac
if (($# > 1)); then echo 'Too many arguments' >&2; exit 2; fi

config="$HOME/.config"
applets="$config/plasma-org.kde.plasma.desktop-appletsrc"
logo="${KDE_LOGO:-/usr/share/pixmaps/archlinux-logo.svg}"
for file in "$applets" "$config/plasmashellrc" "$config/kwinrc" "$logo"; do
  [[ -f $file ]] || { echo "Missing required file: $file" >&2; exit 1; }
done

# Read only section IDs; never assume that a panel or launcher has a fixed ID.
mapfile -t panels < <(awk '
  /^\[Containments\]\[[0-9]+\]$/ { section=$0; next }
  /^plugin=org.kde.panel$/ && section ~ /^\[Containments\]\[[0-9]+\]$/ {
    id=section; sub(/^\[Containments\]\[/,"",id); sub(/\]$/,"",id); print id
  }
' "$applets")
if ((${#panels[@]} != 1)); then
  echo 'Expected exactly one Plasma panel; choose settings manually for multi-panel desktops.' >&2
  exit 1
fi
panel=${panels[0]}
mapfile -t launchers < <(awk -v panel="$panel" '
  /^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$/ { section=$0; next }
  /^plugin=org.kde.plasma.kickoff$/ && section ~ ("^\\[Containments\\]\\[" panel "\\]\\[Applets\\]\\[[0-9]+\\]$") {
    id=section; sub(/^.*\[Applets\]\[/,"",id); sub(/\]$/,"",id); print id
  }
' "$applets")
if ((${#launchers[@]} != 1)); then
  echo 'Expected exactly one Kickoff launcher in the panel; set its icon manually.' >&2
  exit 1
fi
launcher=${launchers[0]}

printf 'KDE plan: enable translucency; set Panel %s floating with translucent background; set Kickoff %s icon to Arch logo.\n' "$panel" "$launcher"
if [[ $apply == false ]]; then exit 0; fi
command -v kwriteconfig6 >/dev/null || { echo 'Missing kwriteconfig6 (Plasma 6 required).' >&2; exit 1; }

for file in "$config/kwinrc" "$config/plasmashellrc" "$applets"; do
  backup=$(mktemp "$file.backup.XXXXXXXX")
  cp -p "$file" "$backup"
  printf 'Backup: %s\n' "$backup"
done
kwriteconfig6 --file kwinrc --group Plugins --key translucencyEnabled true
kwriteconfig6 --file kwinrc --group Effect-translucency --key ExcludeFullScreen true
kwriteconfig6 --file kwinrc --group Effect-translucency --key Inactive 100
kwriteconfig6 --file kwinrc --group Effect-translucency --key Menus 94
kwriteconfig6 --file kwinrc --group Effect-translucency --key MoveResize 94
kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $panel" --key floating 1
kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $panel" --key panelOpacity 2
kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
  --group Containments --group "$panel" --group Applets --group "$launcher" \
  --group Configuration --group General --key icon "$logo"
echo 'Log out and back in to apply the KDE changes. Restore from the printed backups if needed.'
