#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: bash terminal.sh [--apply]   # preview or install Zsh, Meslo Nerd Font, and Powerlevel10k'
}
case "${1:-}" in
  '') apply=false ;;
  --apply) apply=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if (($# > 1)); then usage >&2; exit 2; fi

if [[ ! -r /etc/os-release ]] || ! grep -q '^ID=arch$' /etc/os-release; then
  echo 'This installer supports Arch Linux only.' >&2
  exit 1
fi

cat <<'EOF'
Terminal setup plan:
  1. sudo pacman -S --needed zsh ttf-meslo-nerd (configured Arch mirrors).
  2. Clone Powerlevel10k v1.20.0 from github.com/romkatv/powerlevel10k over HTTPS.
  3. Preserve existing ~/.zshrc and ~/.p10k.zsh; add a theme setup only when absent.
  4. Change the current user's login shell to Zsh with chsh; log out and back in.
EOF
if [[ $apply == false ]]; then exit 0; fi
if [[ $EUID == 0 ]]; then echo 'Run as your regular user, not root.' >&2; exit 1; fi
for cmd in sudo pacman git chsh; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done

sudo pacman -S --needed zsh ttf-meslo-nerd
command -v zsh >/dev/null || { echo 'Zsh is not available after package installation.' >&2; exit 1; }

theme="$HOME/.local/share/powerlevel10k"
stage=''
if [[ ! -e $theme ]]; then
  stage=$(mktemp -d "${TMPDIR:-/tmp}/powerlevel10k.XXXXXXXX")
  trap 'rm -rf -- "$stage"' EXIT
  git clone --depth 1 --branch v1.20.0 https://github.com/romkatv/powerlevel10k.git "$stage/theme"
fi
candidate=${stage:+$stage/theme}
candidate=${candidate:-$theme}
if [[ ! -f $candidate/powerlevel10k.zsh-theme || ! -f $candidate/config/p10k-lean.zsh ]]; then
  echo "Powerlevel10k is incomplete at $theme; refusing to overwrite it." >&2
  exit 1
fi

current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
if [[ $current_shell != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)"
fi
if [[ -n $stage ]]; then
  if [[ -e $theme ]]; then
    echo "Powerlevel10k appeared at $theme while preparing installation; refusing to overwrite it." >&2
    exit 1
  fi
  mkdir -p "$(dirname "$theme")"
  mv -- "$candidate" "$theme"
fi
if [[ ! -e $HOME/.p10k.zsh ]]; then
  cp -- "$theme/config/p10k-lean.zsh" "$HOME/.p10k.zsh"
fi
zshrc="$HOME/.zshrc"
if [[ ! -e $zshrc ]] || ! grep -Fq '# Powerlevel10k (arch-setup terminal.sh)' "$zshrc"; then
  cat >> "$zshrc" <<'EOF'

# Powerlevel10k (arch-setup terminal.sh)
export PATH="$HOME/.local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
source "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
EOF
fi

echo 'Log out and back in for Zsh to become your login shell.'
