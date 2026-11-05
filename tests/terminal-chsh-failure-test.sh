#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d /tmp/opencode/terminal-chsh-failure.XXXXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home" TMPDIR="$scratch/tmp"
mkdir -p "$HOME/.local/share/powerlevel10k/config" "$TMPDIR" "$scratch/bin"
printf 'original\n' > "$HOME/.zshrc"
printf 'theme\n' > "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"
printf 'lean\n' > "$HOME/.local/share/powerlevel10k/config/p10k-lean.zsh"
before=$(sha256sum "$HOME/.zshrc")
for cmd in sudo git zsh; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$scratch/bin/$cmd"
done
printf '#!/usr/bin/env bash\nprintf "user:x:1000:1000::/home/user:/bin/bash\\n"\n' > "$scratch/bin/getent"
printf '#!/usr/bin/env bash\necho "chsh denied" >&2\nexit 1\n' > "$scratch/bin/chsh"
chmod +x "$scratch/bin/"*
export PATH="$scratch/bin:$PATH"
if bash "$repo/terminal.sh" --apply > "$scratch/out" 2> "$scratch/err"; then
  echo 'Expected chsh failure' >&2; exit 1
fi
grep -Fxq 'chsh denied' "$scratch/err"
test "$(sha256sum "$HOME/.zshrc")" = "$before"
test ! -e "$HOME/.p10k.zsh"
echo 'Shell-change failure test passed'
