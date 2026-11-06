#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d /tmp/opencode/agent-browser-test.XXXXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home" AGENT_BROWSER_TEST_LOG="$scratch/calls"
mkdir -p "$HOME" "$scratch/bin"

cat > "$scratch/bin/node" <<'EOF'
#!/usr/bin/env bash
echo "v${TEST_NODE_VERSION:-24.22.2}"
EOF
cat > "$scratch/bin/npm" <<'EOF'
#!/usr/bin/env bash
printf 'npm %s\n' "$*" >> "$HOME/../calls"
printf '%s|%s\n' "${npm_config__authToken-unset}" "${npm_config_proxy-unset}" > "$HOME/npm-env"
mkdir -p "$HOME/.local/bin"
version=0.41.2
if [[ -f $HOME/bad-version ]]; then version=0.40.0; fi
cat > "$HOME/.local/bin/agent-browser" <<'BROWSER'
#!/usr/bin/env bash
printf 'agent-browser %s\n' "$*" >> "$AGENT_BROWSER_TEST_LOG"
if [[ ${1:-} == --version ]]; then echo "agent-browser $(cat "$HOME/installed-version")"; fi
BROWSER
printf '%s\n' "$version" > "$HOME/installed-version"
chmod +x "$HOME/.local/bin/agent-browser"
EOF
chmod +x "$scratch/bin/"*
export PATH="$scratch/bin:$PATH"

bash "$repo/agent-browser.sh" > "$scratch/plan"
grep -Fq 'agent-browser@0.41.2' "$scratch/plan"
test ! -e "$AGENT_BROWSER_TEST_LOG"
test ! -e "$HOME/.local/bin/agent-browser"

TEST_NODE_VERSION=20.0.0 bash "$repo/agent-browser.sh" --apply > "$scratch/out" 2> "$scratch/err" && exit 1
grep -Fq 'Node.js 22 or newer' "$scratch/err"
test ! -e "$AGENT_BROWSER_TEST_LOG"

bash "$repo/agent-browser.sh" --apply > "$scratch/out"
grep -Fq 'agent-browser@0.41.2' "$AGENT_BROWSER_TEST_LOG"
test "$(cat "$HOME/npm-env")" = 'unset|unset'
grep -Fxq 'agent-browser install' "$AGENT_BROWSER_TEST_LOG"
grep -Fxq 'agent-browser --version' "$AGENT_BROWSER_TEST_LOG"
test "$(grep -c '^npm ' "$AGENT_BROWSER_TEST_LOG")" -eq 1

bash "$repo/agent-browser.sh" --apply > "$scratch/repeated"
test "$(grep -c '^npm ' "$AGENT_BROWSER_TEST_LOG")" -eq 1
test "$(grep -c '^agent-browser install$' "$AGENT_BROWSER_TEST_LOG")" -eq 2

# A successful package-manager exit does not prove the pinned CLI was installed.
: > "$HOME/bad-version"
printf '0.40.0\n' > "$HOME/installed-version"
export npm_config__authToken=private-token-mock npm_config_proxy=https://unauthorized.invalid
if bash "$repo/agent-browser.sh" --apply > "$scratch/wrong-version" 2> "$scratch/wrong-version-err"; then
  echo 'Incorrect installed version was accepted' >&2; exit 1
fi
grep -Fq 'Expected agent-browser 0.41.2' "$scratch/wrong-version-err"
test "$(cat "$HOME/npm-env")" = 'unset|unset'
test "$(grep -c '^agent-browser install$' "$AGENT_BROWSER_TEST_LOG")" -eq 2
echo 'Agent-browser setup tests passed'
