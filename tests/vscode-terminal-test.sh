#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d /tmp/opencode/vscode-terminal-test.XXXXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home"
settings="$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json"
mkdir -p "$(dirname "$settings")"
cat > "$settings" <<'EOF'
{"workbench.iconTheme":"material-icon-theme","terminal.integrated.profiles.linux":{"bash":{"path":"bash"}}}
EOF
before=$(sha256sum "$settings")
bash "$repo/vscode-terminal.sh" > "$scratch/preview"
test "$(sha256sum "$settings")" = "$before"
grep -Fq 'host-spawn' "$scratch/preview"

bash "$repo/vscode-terminal.sh" --apply > "$scratch/applied"
python3 - "$settings" <<'PY'
import json
import sys

settings = json.load(open(sys.argv[1], encoding="utf-8"))
assert settings["workbench.iconTheme"] == "material-icon-theme"
profiles = settings["terminal.integrated.profiles.linux"]
assert profiles["bash"] == {"path": "bash"}
assert profiles["zsh (host)"] == {
    "path": "/app/bin/host-spawn",
    "args": ["/usr/bin/zsh", "-l"],
}
assert settings["terminal.integrated.defaultProfile.linux"] == "zsh (host)"
assert settings["terminal.integrated.fontFamily"] == "MesloLGS Nerd Font Mono"
PY
after=$(sha256sum "$settings")
bash "$repo/vscode-terminal.sh" --apply > "$scratch/repeated"
test "$(sha256sum "$settings")" = "$after"

printf '{invalid\n' > "$settings"
before=$(sha256sum "$settings")
if bash "$repo/vscode-terminal.sh" --apply > "$scratch/rejected" 2>&1; then
  echo 'Malformed settings unexpectedly accepted' >&2; exit 1
fi
test "$(sha256sum "$settings")" = "$before"
echo 'VS Code terminal tests passed'
