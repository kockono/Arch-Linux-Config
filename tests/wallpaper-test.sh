#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home" WALLPAPER_TEST_LOG="$scratch/calls"
export WALLPAPER_TEST_STATE="$scratch/installed"
mkdir -p "$HOME/.config" "$scratch/bin"
printf 'original wallpaper\n' > "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
cp "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$scratch/original"
cat > "$scratch/bin/pacman" <<'EOF'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >> "$WALLPAPER_TEST_LOG"
[[ ${MISSING_DEPS:-0} == 0 ]]
EOF
cat > "$scratch/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "$WALLPAPER_TEST_LOG"
while (($#)); do
  if [[ $1 == --output ]]; then printf 'fixture\n' > "$2"; break; fi
  shift
done
EOF
cat > "$scratch/bin/sha256sum" <<'EOF'
#!/usr/bin/env bash
read -r checksum archive
[[ $checksum == 4f144fbe6b29b2aaad173ce9c989c411f59463e520daf9fd59b3211bfdc7b7c2 ]]
[[ -f $archive ]]
printf 'checksum\n' >> "$WALLPAPER_TEST_LOG"
[[ ${BAD_CHECKSUM:-0} == 0 ]]
EOF
cat > "$scratch/bin/kpackagetool6" <<'EOF'
#!/usr/bin/env bash
printf 'kpackage %s\n' "$*" >> "$WALLPAPER_TEST_LOG"
case "$3" in
  --show) test -f "$WALLPAPER_TEST_STATE" ;;
  --install) test -f "$4"; touch "$WALLPAPER_TEST_STATE" ;;
  *) exit 99 ;;
esac
EOF
chmod +x "$scratch/bin/"*
export PATH="$scratch/bin:$PATH"
bash "$repo/wallpaper.sh" > "$scratch/plan"
grep -q 'Smart Video Wallpaper Reborn' "$scratch/plan"
test ! -e "$WALLPAPER_TEST_LOG"
bash "$repo/wallpaper.sh" --help > "$scratch/help"
grep -q 'Usage:' "$scratch/help"
for args in '--unknown' '--apply extra'; do
  status=0
  bash "$repo/wallpaper.sh" $args > "$scratch/out" 2> "$scratch/err" || status=$?
  test "$status" -eq 2
  test ! -e "$WALLPAPER_TEST_LOG"
done
mkdir "$scratch/empty-bin"
status=0
PATH="$scratch/empty-bin" /bin/bash "$repo/wallpaper.sh" --apply > "$scratch/out" 2> "$scratch/err" || status=$?
test "$status" -eq 1
grep -qx 'Missing required command: kpackagetool6' "$scratch/err"
test ! -e "$WALLPAPER_TEST_LOG"
for failure in MISSING_DEPS BAD_CHECKSUM; do
  status=0
  env "$failure=1" bash "$repo/wallpaper.sh" --apply > "$scratch/out" 2> "$scratch/err" || status=$?
  test "$status" -ne 0
  test ! -e "$WALLPAPER_TEST_STATE"
  ! grep -q -- '--install' "$WALLPAPER_TEST_LOG"
  cmp "$scratch/original" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  : > "$WALLPAPER_TEST_LOG"
done
bash "$repo/wallpaper.sh" --apply > "$scratch/out"
test -f "$WALLPAPER_TEST_STATE"
grep -q 'releases/download/v2.16.0/plasma-smart-video-wallpaper-reborn-v2.16.0.tar.gz' "$WALLPAPER_TEST_LOG"
test "$(grep -c -- '--install' "$WALLPAPER_TEST_LOG")" -eq 1
grep -q '^checksum$' "$WALLPAPER_TEST_LOG"
: > "$WALLPAPER_TEST_LOG"
bash "$repo/wallpaper.sh" --apply > "$scratch/out"
! grep -Eq 'curl|--install' "$WALLPAPER_TEST_LOG"
cmp "$scratch/original" "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
echo 'wallpaper tests passed'
