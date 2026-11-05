#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/home" "$scratch/bin"
export HOME="$scratch/home" PATH="$scratch/bin:$PATH" BOOTSTRAP_TEST_LOG="$scratch/calls"
mkdir -p "$scratch/fixture"
cat > "$scratch/fixture/rtk" <<'EOF'
#!/usr/bin/env bash
echo 'rtk 1.1.0'
EOF
chmod +x "$scratch/fixture/rtk"
printf 'license\n' > "$scratch/fixture/LICENSE"
printf 'engine license\n' > "$scratch/fixture/LICENSE-ENGINE"
tar -czf "$scratch/rtk.tar.gz" -C "$scratch/fixture" rtk LICENSE LICENSE-ENGINE
export RTK_TEST_ARCHIVE="$scratch/rtk.tar.gz"
cat > "$scratch/fixture/Antigravity" <<'EOF'
#!/usr/bin/env bash
echo 'Antigravity test launcher'
EOF
chmod +x "$scratch/fixture/Antigravity"
tar -czf "$scratch/Antigravity.tar.gz" -C "$scratch/fixture" Antigravity
cat > "$scratch/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
if [[ ${FAIL_DESKTOP:-} == 1 && $* == "pacman -U $DOCKER_TEST_PACKAGE" ]]; then exit 1; fi
if [[ ${FAIL_RESTORE:-} == 1 && $* == 'pacman -S --needed docker-compose' ]]; then exit 1; fi
EOF
cat > "$scratch/bin/go" <<'EOF'
#!/usr/bin/env bash
printf 'go %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
case "$*" in
  *'/gentle-ai@'*) name=gentle-ai ;;
  *'/engram@'*) name=engram ;;
  *) exit 1 ;;
esac
cat > "$GOBIN/$name" <<INNER
#!/usr/bin/env bash
printf '$name %s\\n' "\$*" >> "\$BOOTSTRAP_TEST_LOG"
INNER
chmod +x "$GOBIN/$name"
EOF
cat > "$scratch/bin/engram" <<'EOF'
#!/usr/bin/env bash
printf 'engram %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF
cat > "$scratch/bin/gentle-ai" <<'EOF'
#!/usr/bin/env bash
printf 'gentle-ai %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF
cat > "$scratch/bin/npm" <<'EOF'
#!/usr/bin/env bash
printf 'npm %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF
cat > "$scratch/bin/yay" <<'EOF'
#!/usr/bin/env bash
printf 'yay %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF
cat > "$scratch/bin/flatpak" <<'EOF'
#!/usr/bin/env bash
printf 'flatpak %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF
cat > "$scratch/bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == -Qip ]]; then
  printf 'Name            : %s\nArchitecture    : x86_64\n' "${DOCKER_PACKAGE_NAME:-docker-desktop}"
  exit 0
fi
[[ $* == '-Qq docker-compose' && ${COMPOSE_INSTALLED:-} == 1 ]]
EOF
cat > "$scratch/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
[[ $* == *'https://github.com/rtk-ai/rtk/releases/download/v1.1.0/rtk-x86_64-unknown-linux-musl.tar.gz'* ]] || exit 1
while (($#)); do
  if [[ $1 == --output ]]; then cp "$RTK_TEST_ARCHIVE" "$2"; exit 0; fi
  shift
done
exit 1
EOF
cat > "$scratch/bin/sha256sum" <<'EOF'
#!/usr/bin/env bash
read -r checksum file
printf 'sha256sum %s %s\n' "$checksum" "$file" >> "$BOOTSTRAP_TEST_LOG"
[[ $1 == --check && $2 == - && $checksum == 9454ad1b9489daa57ab0a9f4ebe2faaf4dc82b8a0f26c9e5135151abd7c9378d && -f $file && ${RTK_BAD_HASH:-} != 1 ]]
EOF
chmod +x "$scratch/bin/"*

bash "$repo/bootstrap.sh" > "$scratch/plan"
test ! -e "$scratch/calls" || { echo 'dry run executed commands' >&2; exit 1; }
grep -q 'git github-cli opencode go nodejs npm piper openrgb discord coolercontrol' "$scratch/plan"
grep -q '^  2\. sudo pacman -S --needed mpv clang cmake ninja$' "$scratch/plan"
grep -q 'Warp' "$scratch/plan"
grep -q 'RTK' "$scratch/plan"
grep -q 'Gemini CLI' "$scratch/plan"
grep -q 'Google Antigravity' "$scratch/plan"
grep -q 'Zoom' "$scratch/plan"
grep -q 'Docker Desktop' "$scratch/plan"
grep -q 'Visual Studio Code.*Flatpak' "$scratch/plan"
if bash "$repo/bootstrap.sh" --warp-package "$scratch/missing.pkg.tar.zst" > "$scratch/out" 2> "$scratch/err"; then
  echo 'dry run ignored explicitly invalid Warp path' >&2
  exit 1
fi
test -s "$scratch/err"
if bash "$repo/bootstrap.sh" --warp-package '' > "$scratch/out" 2> "$scratch/err"; then
  echo 'dry run ignored explicitly empty Warp path' >&2
  exit 1
fi
test ! -s "$scratch/out" && test -s "$scratch/err"
if bash "$repo/bootstrap.sh" --warp-package "$scratch/missing.pkg.tar.zst" --help > "$scratch/out" 2> "$scratch/err"; then
  echo 'help ignored an invalid earlier Warp option' >&2
  exit 1
fi
test ! -s "$scratch/out" && test -s "$scratch/err"
bash "$repo/bootstrap.sh" --help > "$scratch/out"
grep -q '^Usage: bash bootstrap.sh' "$scratch/out"
touch "$scratch/warp.pkg.tar.zst"
touch "$scratch/docker-desktop.pkg.tar.zst"
export DOCKER_TEST_PACKAGE="$scratch/docker-desktop.pkg.tar.zst"
if bash "$repo/bootstrap.sh" --docker-desktop-package "$scratch/missing.pkg.tar.zst" > "$scratch/out" 2> "$scratch/err"; then
  echo 'nonexistent Docker Desktop package accepted' >&2; exit 1
fi
test ! -s "$scratch/out" && test -s "$scratch/err"
if bash "$repo/bootstrap.sh" --docker-desktop-package "$scratch/docker-desktop.pkg.tar.zst" --docker-desktop-package "$scratch/docker-desktop.pkg.tar.zst" > "$scratch/out" 2> "$scratch/err"; then
  echo 'repeated Docker Desktop package option accepted' >&2; exit 1
fi
test ! -s "$scratch/out" && test -s "$scratch/err"
if bash "$repo/bootstrap.sh" --warp-package "$scratch/missing.pkg.tar.zst" --warp-package "$scratch/warp.pkg.tar.zst" > "$scratch/out" 2> "$scratch/err"; then
  echo 'dry run ignored a repeated Warp option' >&2
  exit 1
fi
test ! -s "$scratch/out" && test -s "$scratch/err"
if bash "$repo/bootstrap.sh" --apply > "$scratch/out" 2>&1; then
  echo 'apply without Warp package succeeded' >&2
  exit 1
fi
test ! -e "$scratch/calls" || { echo 'invalid apply executed commands' >&2; exit 1; }
if bash "$repo/bootstrap.sh" --apply --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/missing.tar.gz" > "$scratch/out" 2> "$scratch/err"; then
  echo 'invalid Antigravity archive path was accepted' >&2
  exit 1
fi
test ! -e "$scratch/calls" || { echo 'invalid archive started installation' >&2; exit 1; }
if DOCKER_PACKAGE_NAME=unrelated bash "$repo/bootstrap.sh" --apply --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" --docker-desktop-package "$scratch/docker-desktop.pkg.tar.zst" > "$scratch/out" 2> "$scratch/err"; then
  echo 'non-Docker package accepted as Docker Desktop' >&2; exit 1
fi
test ! -e "$scratch/calls" || { echo 'wrong package started installation' >&2; exit 1; }
if COMPOSE_INSTALLED=1 bash "$repo/bootstrap.sh" --apply --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" --docker-desktop-package "$scratch/docker-desktop.pkg.tar.zst" > "$scratch/out" 2> "$scratch/err"; then
  echo 'existing Compose package was silently replaced' >&2; exit 1
fi
test ! -e "$scratch/calls" || { echo 'Compose conflict started installation' >&2; exit 1; }
mkdir -p "$HOME/.local/opt/google-antigravity"
if bash "$repo/bootstrap.sh" --apply --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" > "$scratch/out" 2> "$scratch/err"; then
  echo 'existing Antigravity installation was overwritten' >&2
  exit 1
fi
rmdir "$HOME/.local/opt/google-antigravity"
test ! -e "$scratch/calls" || { echo 'existing app started installation' >&2; exit 1; }
mkdir -p "$scratch/unsafe"
ln -s /bin/true "$scratch/unsafe/Antigravity"
tar -czf "$scratch/unsafe.tar.gz" -C "$scratch/unsafe" Antigravity
if bash "$repo/bootstrap.sh" --apply --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/unsafe.tar.gz" > "$scratch/out" 2> "$scratch/err"; then
  echo 'external Antigravity launcher symlink was accepted' >&2
  exit 1
fi
test ! -e "$scratch/calls" || { echo 'unsafe archive started installation' >&2; exit 1; }
test ! -e "$HOME/.local/opt/google-antigravity" || { echo 'unsafe archive installed app' >&2; exit 1; }
if RTK_BAD_HASH=1 bash "$repo/bootstrap.sh" --apply --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" > "$scratch/out" 2> "$scratch/err"; then
  echo 'corrupt RTK archive installed without verification' >&2
  exit 1
fi
test ! -e "$HOME/.local/bin/rtk" || { echo 'RTK installed after checksum failure' >&2; exit 1; }
: > "$scratch/calls"
bash "$repo/bootstrap.sh" --apply --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" --docker-desktop-package "$scratch/docker-desktop.pkg.tar.zst" > "$scratch/out"
grep -q '^sudo pacman -Syu --needed git github-cli opencode go nodejs npm piper openrgb discord coolercontrol$' "$scratch/calls"
grep -q '^sudo pacman -S --needed mpv clang cmake ninja$' "$scratch/calls"
grep -qx 'sudo pacman -S --needed flatpak' "$scratch/calls"
grep -qx 'flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' "$scratch/calls"
grep -qx 'flatpak install --user --assumeyes --noninteractive flathub com.visualstudio.code' "$scratch/calls"
if grep -Eq '(systemctl|pwmconfig|fancontrol)' "$scratch/calls"; then
  echo 'fan service or curve was changed without hardware validation' >&2
  exit 1
fi
grep -q '^sudo pacman -U ' "$scratch/calls"
grep -q '^yay -S --needed zoom$' "$scratch/calls"
grep -q "^sudo pacman -U $scratch/docker-desktop.pkg.tar.zst$" "$scratch/calls"
if grep -q '^sudo pacman -R docker-compose$' "$scratch/calls"; then
  echo 'Compose removed when not installed' >&2; exit 1
fi
grep -q '^go install github.com/gentleman-programming/gentle-ai/v4/cmd/gentle-ai@v4.3.1$' "$scratch/calls"
grep -q '^go install github.com/Gentleman-Programming/engram/cmd/engram@v3.6.1$' "$scratch/calls"
grep -q '^engram setup opencode$' "$scratch/calls"
grep -q '^gentle-ai install --dry-run$' "$scratch/calls"
grep -q '^npm install -g @google/gemini-cli@0.66.0$' "$scratch/calls"
test -x "$HOME/.local/opt/google-antigravity/Antigravity"
rm -rf "$HOME/.local/opt/google-antigravity"
: > "$scratch/calls"
COMPOSE_INSTALLED=1 bash "$repo/bootstrap.sh" --apply --replace-compose --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" --docker-desktop-package "$scratch/docker-desktop.pkg.tar.zst" > "$scratch/out"
grep -q '^sudo pacman -R docker-compose$' "$scratch/calls"
grep -q "^sudo pacman -U $scratch/docker-desktop.pkg.tar.zst$" "$scratch/calls"
grep -q '^curl .*rtk-x86_64-unknown-linux-musl.tar.gz' "$scratch/calls"
grep -q '^sha256sum 9454ad1b9489daa57ab0a9f4ebe2faaf4dc82b8a0f26c9e5135151abd7c9378d ' "$scratch/calls"
test -x "$HOME/.local/bin/rtk"
grep -q '^rtk 1.1.0$' <("$HOME/.local/bin/rtk" --version)
if grep -q 'rtk init' "$scratch/calls"; then
  echo 'RTK integration was enabled without permission' >&2
  exit 1
fi
if grep -q '^gentle-ai install$' "$scratch/calls"; then
  echo 'interactive installer was started without consent' >&2
  exit 1
fi
rm -rf "$HOME/.local/opt/google-antigravity"
: > "$scratch/calls"
if COMPOSE_INSTALLED=1 FAIL_DESKTOP=1 bash "$repo/bootstrap.sh" --apply --replace-compose --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" --docker-desktop-package "$DOCKER_TEST_PACKAGE" > "$scratch/out" 2> "$scratch/err"; then
  echo 'Docker Desktop install failure was ignored' >&2; exit 1
fi
grep -q '^sudo pacman -S --needed docker-compose$' "$scratch/calls"
test -s "$scratch/err"
rm -rf "$HOME/.local/opt/google-antigravity"
: > "$scratch/calls"
if COMPOSE_INSTALLED=1 FAIL_DESKTOP=1 FAIL_RESTORE=1 bash "$repo/bootstrap.sh" --apply --replace-compose --warp-package "$scratch/warp.pkg.tar.zst" --antigravity-archive "$scratch/Antigravity.tar.gz" --docker-desktop-package "$DOCKER_TEST_PACKAGE" > "$scratch/out" 2> "$scratch/err"; then
  echo 'failed Compose restoration was ignored' >&2; exit 1
fi
grep -q 'Restore docker-compose manually' "$scratch/err"
echo 'bootstrap tests passed'
