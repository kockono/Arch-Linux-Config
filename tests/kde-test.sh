#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home" KDE_LOGO="$scratch/arch.svg" KDE_TEST_LOG="$scratch/calls"
mkdir -p "$HOME/.config" "$scratch/bin"
touch "$KDE_LOGO"
cat > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'EOF'
[Containments][7]
plugin=org.kde.panel
[Containments][7][Applets][12]
plugin=org.kde.plasma.kickoff
EOF
touch "$HOME/.config/kwinrc" "$HOME/.config/plasmashellrc"
cat > "$scratch/bin/kwriteconfig6" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$KDE_TEST_LOG"
EOF
chmod +x "$scratch/bin/kwriteconfig6"
export PATH="$scratch/bin:$PATH"
bash "$repo/kde.sh" > "$scratch/plan"
test ! -e "$KDE_TEST_LOG" || { echo 'dry run changed KDE' >&2; exit 1; }
grep -q 'Panel 7' "$scratch/plan"
bash "$repo/kde.sh" --apply > "$scratch/out"
grep -q -- '--file kwinrc --group Plugins --key translucencyEnabled true' "$KDE_TEST_LOG"
grep -q -- '--file plasmashellrc --group PlasmaViews --group Panel 7 --key floating 1' "$KDE_TEST_LOG"
grep -q -- '--file plasmashellrc --group PlasmaViews --group Panel 7 --key panelOpacity 2' "$KDE_TEST_LOG"
grep -q -- '--group 12 --group Configuration --group General --key icon ' "$KDE_TEST_LOG"
test "$(find "$HOME/.config" -name 'plasmashellrc.backup.*' | wc -l)" -eq 1
echo 'KDE tests passed'
