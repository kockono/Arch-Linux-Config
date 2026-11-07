#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/bin"
export DBEAVER_TEST_LOG="$scratch/calls"
cat > "$scratch/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DBEAVER_TEST_LOG"
exit "${DBEAVER_TEST_STATUS:-0}"
EOF
chmod +x "$scratch/bin/sudo"
export PATH="$scratch/bin:$PATH"
bash "$repo/dbeaver.sh" > "$scratch/plan"
grep -q 'DBeaver Community' "$scratch/plan"
test ! -e "$scratch/calls"
bash "$repo/dbeaver.sh" --help > "$scratch/help"
grep -q -- '--apply' "$scratch/help"
for args in '--unknown' '--apply extra'; do
  status=0
  bash "$repo/dbeaver.sh" $args > "$scratch/out" 2> "$scratch/err" || status=$?
  test "$status" -eq 2
  test -s "$scratch/err"
  test ! -e "$scratch/calls"
done
bash "$repo/dbeaver.sh" --apply > "$scratch/out"
test "$(cat "$scratch/calls")" = 'pacman -Syu --needed dbeaver'
grep -q 'Launch DBeaver' "$scratch/out"
: > "$scratch/calls"
status=0
DBEAVER_TEST_STATUS=17 bash "$repo/dbeaver.sh" --apply > "$scratch/out" 2> "$scratch/err" || status=$?
test "$status" -eq 17
! grep -q 'Launch DBeaver' "$scratch/out"
echo 'dbeaver tests passed'
