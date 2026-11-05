#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d /tmp/opencode/vscode-link-test.XXXXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home" TMPDIR="$scratch"
user_dir="$HOME/.var/app/com.visualstudio.code/config/Code/User"
mkdir -p "$(dirname "$user_dir")" "$scratch/elsewhere"
printf '{"unrelated":true}\n' > "$scratch/elsewhere/settings.json"
ln -s "$scratch/elsewhere" "$user_dir"
before=$(sha256sum "$scratch/elsewhere/settings.json")
if bash "$repo/vscode-terminal.sh" --apply > "$scratch/out" 2> "$scratch/err"; then
  echo 'Redirected settings unexpectedly accepted' >&2
  exit 1
fi
test "$(sha256sum "$scratch/elsewhere/settings.json")" = "$before"
echo 'VS Code symlink refusal passed'
