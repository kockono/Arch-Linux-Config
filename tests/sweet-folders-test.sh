#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home"
mkdir -p "$HOME/.config" "$scratch/bin"
printf '[Icons]\nTheme=breeze\n' > "$HOME/.config/kdeglobals"
before=$(sha256sum "$HOME/.config/kdeglobals")
bash "$repo/sweet-folders.sh" > "$scratch/plan"
grep -q Sweet-Purple "$scratch/plan"
test ! -d "$HOME/.local/share/icons"
test "$before" = "$(sha256sum "$HOME/.config/kdeglobals")"
bash "$repo/sweet-folders.sh" --help | grep -q Usage
if bash "$repo/sweet-folders.sh" --invalid > /dev/null 2>&1; then exit 1; else test "$?" -eq 2; fi
if bash "$repo/sweet-folders.sh" --apply extra > /dev/null 2>&1; then exit 1; else test "$?" -eq 2; fi

# A corrupted download must fail before installing icons or changing settings.
cat > "$scratch/bin/curl" <<'EOF'
#!/usr/bin/env bash
while (($#)); do
  if [[ $1 == --output ]]; then printf 'corrupt archive' > "$2"; exit 0; fi
  shift
done
exit 1
EOF
chmod +x "$scratch/bin/"*
if LC_ALL=C PATH="$scratch/bin:$PATH" bash "$repo/sweet-folders.sh" --apply > "$scratch/rejected" 2>&1; then
  echo 'Corrupt download was accepted' >&2; exit 1
fi
grep -q 'FAILED' "$scratch/rejected"
test ! -d "$HOME/.local/share/icons"
test "$before" = "$(sha256sum "$HOME/.config/kdeglobals")"

# Reusing installed themes must not download or overwrite their contents.
mkdir -p "$HOME/.local/share/icons/"{Sweet-Purple,candy-icons}
printf '[Icon Theme]\nName=Sweet-Purple\nInherits=candy-icons\n' > "$HOME/.local/share/icons/Sweet-Purple/index.theme"
printf '[Icon Theme]\nName=Candy\n' > "$HOME/.local/share/icons/candy-icons/index.theme"
themes_before=$(find "$HOME/.local/share/icons" -type f -exec sha256sum {} +)
PATH="$scratch/bin:$PATH" DBUS_SESSION_BUS_ADDRESS='' bash "$repo/sweet-folders.sh" --apply > "$scratch/applied"
grep -q '^Theme=Sweet-Purple$' "$HOME/.config/kdeglobals"
test "$(cat "$HOME/.config/"kdeglobals.backup.*)" = $'[Icons]\nTheme=breeze'
test "$themes_before" = "$(find "$HOME/.local/share/icons" -type f -exec sha256sum {} +)"
PATH="$scratch/bin:$PATH" DBUS_SESSION_BUS_ADDRESS='' bash "$repo/sweet-folders.sh" --apply > "$scratch/repeated"
grep -q '^Theme=Sweet-Purple$' "$HOME/.config/kdeglobals"
test "$themes_before" = "$(find "$HOME/.local/share/icons" -type f -exec sha256sum {} +)"
echo 'Sweet folders tests passed'
