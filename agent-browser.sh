#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: bash agent-browser.sh [--apply]   # preview or install agent-browser for this user'
}
case "${1:-}" in
  '') apply=false ;;
  --apply) apply=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if (($# > 1)); then usage >&2; exit 2; fi

version=0.41.2
cat <<EOF
Agent-browser setup plan:
  1. Install agent-browser@$version from registry.npmjs.org into ~/.local (only if missing).
  2. Download Chrome for Testing for the current user with agent-browser install.
  3. Check the installed agent-browser version. No sudo or account sign-in.
EOF
if [[ $apply == false ]]; then exit 0; fi
if [[ ! -r /etc/os-release ]] || ! grep -q '^ID=arch$' /etc/os-release; then
  echo 'This installer supports Arch Linux only.' >&2; exit 1
fi
if [[ $EUID == 0 ]]; then echo 'Run as your regular user, not root.' >&2; exit 1; fi
for cmd in node npm; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
node_major=$(node -v)
node_major=${node_major#v}
node_major=${node_major%%.*}
if [[ ! $node_major =~ ^[0-9]+$ ]] || ((node_major < 22)); then
  echo 'Node.js 22 or newer is required.' >&2; exit 1
fi

bin="$HOME/.local/bin/agent-browser"
if [[ ! -x $bin ]] || [[ $($bin --version 2>/dev/null) != "agent-browser $version" ]]; then
  # Ignore package lifecycle scripts: the Linux binary is bundled in this release.
  # Isolate npm configuration so this public download cannot use npm credentials.
  stage=$(mktemp -d "${TMPDIR:-/tmp}/agent-browser-npm.XXXXXXXX")
  trap 'rm -rf -- "$stage"' EXIT
  : > "$stage/npmrc"
  env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" \
    npm_config_userconfig=/dev/null npm_config_globalconfig="$stage/npmrc" \
    npm_config_registry=https://registry.npmjs.org/ \
    npm --prefix "$HOME/.local" install --global --ignore-scripts --no-audit --no-fund "agent-browser@$version"
fi
if [[ ! -x $bin ]]; then echo "agent-browser is missing at $bin" >&2; exit 1; fi
if [[ $($bin --version 2>/dev/null) != "agent-browser $version" ]]; then
  echo "Expected agent-browser $version at $bin; refusing to use a different version." >&2
  exit 1
fi
"$bin" install
"$bin" --version
echo "Installed agent-browser for this user. Add $HOME/.local/bin to PATH if needed."
