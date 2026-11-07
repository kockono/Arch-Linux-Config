#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: bash sweet-folders.sh [--apply]   # preview or install Sweet-Purple folders with Candy icons'
}
apply=false
if (($# > 1)); then usage >&2; exit 2; fi
case "${1:-}" in
  '') ;;
  --apply) apply=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
echo 'Icons plan: install Sweet-Purple folders and missing Candy icons for this user; back up kdeglobals and select Sweet-Purple. Keep panels and other appearance settings unchanged.'
if [[ $apply == false ]]; then exit 0; fi
for tool in curl sha256sum tar kwriteconfig6; do
  command -v "$tool" >/dev/null || { echo "Missing required command: $tool" >&2; exit 1; }
done

icons="$HOME/.local/share/icons"
config="$HOME/.config/kdeglobals"
sweet=40a5d36e50437901c7eaa1119bb9ae8006e2fe5c
candy=750fe2ca7909a721179ec34336042b15808d8ab9
# Refuse to overwrite a pre-existing, incomplete theme directory.
for theme in Sweet-Purple candy-icons; do
  if [[ -e "$icons/$theme" && ! -f "$icons/$theme/index.theme" ]]; then
    echo "Existing theme is incomplete; leaving it unchanged: $icons/$theme" >&2
    exit 1
  fi
done
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
download() {
  local repository=$1 revision=$2 checksum=$3 output=$4
  curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' \
    "https://codeload.github.com/EliverLara/$repository/tar.gz/$revision" --output "$output"
  printf '%s  %s\n' "$checksum" "$output" | sha256sum --check --strict
}
# Check both downloads before touching installed themes or desktop settings.
if [[ ! -f "$icons/Sweet-Purple/index.theme" ]]; then
  download Sweet-folders "$sweet" 386f66922f9811e42a2b1e4018d5f43f759cb5d778c74345a1483d6c076402e5 "$stage/sweet.tar.gz"
  tar --extract --gzip --file "$stage/sweet.tar.gz" --directory "$stage" --no-same-owner \
    "Sweet-folders-$sweet/Sweet-Purple"
fi
if [[ ! -f "$icons/candy-icons/index.theme" ]]; then
  download candy-icons "$candy" 3d938b9ed524ca33ecb6448bb57c07db8c1ec99239c61eae228252b74a3e5e03 "$stage/candy.tar.gz"
  tar --extract --gzip --file "$stage/candy.tar.gz" --directory "$stage" --no-same-owner
fi
mkdir -p "$icons" "$HOME/.config"
if [[ -d "$stage/Sweet-folders-$sweet/Sweet-Purple" ]]; then
  mv "$stage/Sweet-folders-$sweet/Sweet-Purple" "$icons/Sweet-Purple"
fi
if [[ -d "$stage/candy-icons-$candy" ]]; then
  mv "$stage/candy-icons-$candy" "$icons/candy-icons"
fi
if [[ -f $config ]]; then
  backup=$(mktemp "$config.backup.XXXXXXXX")
  cp -p "$config" "$backup"
  printf 'Backup: %s\n' "$backup"
fi
kwriteconfig6 --file "$config" --group Icons --key Theme Sweet-Purple
if command -v dbus-send >/dev/null && [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
  dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:4 int32:0 || true
  dbus-send --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:0 || true
fi
echo 'Selected Sweet-Purple with Candy application icons. Reopen Dolphin if folder icons have not refreshed; log out and back in if needed.'
