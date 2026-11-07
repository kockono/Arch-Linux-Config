#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash dbeaver.sh [--apply]

Preview by default; --apply installs DBeaver Community from Arch's official
repositories using sudo pacman -Syu --needed dbeaver. This also upgrades the
system to avoid partial upgrades. No database connections are configured.
EOF
}
if (($# > 1)); then usage >&2; exit 2; fi
case "${1:-}" in
  '') apply=false ;;
  --apply) apply=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

cat <<'EOF'
DBeaver Community setup plan:
  1. Upgrade Arch packages and install dbeaver from the official repositories.
     sudo pacman -Syu --needed dbeaver
  2. Leave existing database connections and credentials unchanged.
EOF
if [[ $apply == false ]]; then exit 0; fi
if [[ ! -r /etc/os-release ]] || ! grep -q '^ID=arch$' /etc/os-release; then
  echo 'This installer supports Arch Linux only.' >&2; exit 1
fi
if [[ $EUID == 0 ]]; then
  echo 'Run as your regular user; sudo is used only for pacman.' >&2; exit 1
fi
for cmd in sudo pacman; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
sudo pacman -Syu --needed dbeaver
echo 'Launch DBeaver from the application menu or run: dbeaver'
