#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home" NOTIFICATIONS_TEST_LOG="$scratch/calls"
mkdir -p "$HOME/.config" "$scratch/bin"
cat > "$scratch/bin/kwriteconfig6" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$NOTIFICATIONS_TEST_LOG"
printf '\n[Notifications]\nPopupPosition=TopRight\n' >> "$HOME/.config/plasmanotifyrc"
EOF
chmod +x "$scratch/bin/kwriteconfig6"
export PATH="$scratch/bin:$PATH"
printf '[Applications][discord]\nSeen=true\n' > "$HOME/.config/plasmanotifyrc"
cp "$HOME/.config/plasmanotifyrc" "$scratch/original"
bash "$repo/notifications.sh" > "$scratch/plan"
grep -q 'top right' "$scratch/plan"
test ! -e "$NOTIFICATIONS_TEST_LOG"
cmp "$scratch/original" "$HOME/.config/plasmanotifyrc"
bash "$repo/notifications.sh" --help > "$scratch/help"
grep -q 'Usage:' "$scratch/help"
for args in '--unknown' '--apply extra'; do
  status=0
  # Deliberately split the fixed invalid argument fixtures.
  bash "$repo/notifications.sh" $args > "$scratch/out" 2> "$scratch/err" || status=$?
  test "$status" -eq 2
  cmp "$scratch/original" "$HOME/.config/plasmanotifyrc"
  test ! -e "$NOTIFICATIONS_TEST_LOG"
done
bash "$repo/notifications.sh" --apply > "$scratch/out"
grep -qx -- '--file plasmanotifyrc --group Notifications --key PopupPosition --notify TopRight' "$NOTIFICATIONS_TEST_LOG"
mapfile -t backups < <(find "$HOME/.config" -name 'plasmanotifyrc.backup.*')
test "${#backups[@]}" -eq 1
cmp "$scratch/original" "${backups[0]}"
grep -q '^Seen=true$' "$HOME/.config/plasmanotifyrc"
grep -q '^PopupPosition=TopRight$' "$HOME/.config/plasmanotifyrc"
rm "$HOME/.config/plasmanotifyrc"
bash "$repo/notifications.sh" --apply > "$scratch/out"
grep -q '^PopupPosition=TopRight$' "$HOME/.config/plasmanotifyrc"
echo 'notification tests passed'
