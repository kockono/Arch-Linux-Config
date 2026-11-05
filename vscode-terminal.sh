#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: bash vscode-terminal.sh [--apply]   # preview or configure VS Code Flatpak host Zsh'
}
case "${1:-}" in
  '') apply=false ;;
  --apply) apply=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if (($# > 1)); then usage >&2; exit 2; fi

settings="$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json"
printf 'VS Code Flatpak terminal plan: add host Zsh via bundled /app/bin/host-spawn, set it as default, and select MesloLGS Nerd Font Mono in %s.\n' "$settings"
if [[ $apply == false ]]; then exit 0; fi
command -v python3 >/dev/null || { echo 'Python 3 is required to update VS Code settings.' >&2; exit 1; }
if [[ ! -f $settings || -L $settings ]]; then
  echo 'A regular VS Code Flatpak settings.json is required; launch VS Code once and create user settings first.' >&2
  exit 1
fi

python3 - "$settings" <<'PY'
import json
import os
from pathlib import Path
import stat
import sys
import tempfile

settings_path = Path(sys.argv[1])
if settings_path.is_symlink() or any(parent.is_symlink() for parent in settings_path.parents):
    raise SystemExit("Refusing redirected VS Code settings path.")
try:
    with settings_path.open(encoding="utf-8") as source:
        settings = json.load(source)
except (OSError, UnicodeError, json.JSONDecodeError) as error:
    raise SystemExit(f"Cannot safely parse VS Code settings as JSON: {error}. Edit JSONC settings manually.")
if not isinstance(settings, dict):
    raise SystemExit("VS Code settings must be a JSON object.")
profiles = settings.get("terminal.integrated.profiles.linux", {})
if not isinstance(profiles, dict):
    raise SystemExit("Existing terminal.integrated.profiles.linux must be a JSON object.")

profile = {"path": "/app/bin/host-spawn", "args": ["/usr/bin/zsh", "-l"]}
if (profiles.get("zsh (host)") == profile
        and settings.get("terminal.integrated.defaultProfile.linux") == "zsh (host)"
        and settings.get("terminal.integrated.fontFamily") == "MesloLGS Nerd Font Mono"):
    print("VS Code terminal settings are already configured.")
    raise SystemExit(0)

profiles["zsh (host)"] = profile
settings["terminal.integrated.profiles.linux"] = profiles
settings["terminal.integrated.defaultProfile.linux"] = "zsh (host)"
settings["terminal.integrated.fontFamily"] = "MesloLGS Nerd Font Mono"
mode = stat.S_IMODE(settings_path.stat().st_mode)
fd, temp_name = tempfile.mkstemp(prefix=".settings.", dir=settings_path.parent)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as output:
        json.dump(settings, output, ensure_ascii=False, indent=4)
        output.write("\n")
        output.flush()
        os.fsync(output.fileno())
    os.chmod(temp_name, mode)
    if settings_path.is_symlink() or any(parent.is_symlink() for parent in settings_path.parents):
        raise RuntimeError("VS Code settings path changed while preparing the update.")
    os.replace(temp_name, settings_path)
except BaseException:
    if os.path.exists(temp_name):
        os.unlink(temp_name)
    raise
print("Open a new VS Code terminal to use host Zsh.")
PY
