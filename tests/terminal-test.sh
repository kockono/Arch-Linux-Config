#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d /tmp/opencode/terminal-test.XXXXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home" TERMINAL_TEST_LOG="$scratch/calls"
mkdir -p "$HOME" "$scratch/bin"

cat > "$scratch/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$TERMINAL_TEST_LOG"
EOF
cat > "$scratch/bin/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >> "$TERMINAL_TEST_LOG"
if [[ $1 == clone ]]; then
  mkdir -p "${@: -1}/config"
  printf '# lean theme\n' > "${@: -1}/config/p10k-lean.zsh"
  : > "${@: -1}/powerlevel10k.zsh-theme"
fi
EOF
cat > "$scratch/bin/chsh" <<'EOF'
#!/usr/bin/env bash
printf 'chsh %s\n' "$*" >> "$TERMINAL_TEST_LOG"
EOF
printf '#!/usr/bin/env bash\n' > "$scratch/bin/zsh"
chmod +x "$scratch/bin"/*
export PATH="$scratch/bin:$PATH"

bash "$repo/terminal.sh" > "$scratch/plan"
test ! -e "$TERMINAL_TEST_LOG"
test ! -e "$HOME/.zshrc"
grep -q 'zsh ttf-meslo-nerd' "$scratch/plan"

bash "$repo/terminal.sh" --apply > "$scratch/out"
grep -Fxq 'sudo pacman -S --needed zsh ttf-meslo-nerd' "$TERMINAL_TEST_LOG"
grep -Fq 'git clone --depth 1 --branch v1.20.0 https://github.com/romkatv/powerlevel10k.git' "$TERMINAL_TEST_LOG"
grep -Fq 'chsh -s ' "$TERMINAL_TEST_LOG"
grep -Fq 'powerlevel10k.zsh-theme' "$HOME/.zshrc"
grep -Fq '.p10k.zsh' "$HOME/.zshrc"
test -f "$HOME/.p10k.zsh"

bash "$repo/terminal.sh" --apply > "$scratch/repeated"
test "$(grep -c 'powerlevel10k.zsh-theme' "$HOME/.zshrc")" -eq 1
test "$(grep -c '^git clone ' "$TERMINAL_TEST_LOG")" -eq 1
echo 'Terminal setup tests passed'
