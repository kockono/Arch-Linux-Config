#!/usr/bin/env bash
set -euo pipefail

# Plan by default; --apply performs package installation on Arch Linux.
apply=false
help_requested=false
warp_package=''
warp_package_supplied=false
antigravity_archive=''
antigravity_archive_supplied=false
docker_desktop_package=''
docker_desktop_package_supplied=false
replace_compose=false
usage() {
  cat <<'EOF'
Usage: bash bootstrap.sh [--apply --warp-package PATH --antigravity-archive PATH --docker-desktop-package PATH] [--replace-compose]

Without --apply, show the plan without changing the system.
Download the official Arch Linux Warp .pkg.tar.zst from https://www.warp.dev/download
and pass its local path with --warp-package when applying.
Download the official Linux x64 Antigravity App tarball from https://antigravity.google/download/
and pass its local path with --antigravity-archive when applying.
Download the official Arch Docker Desktop .pkg.tar.zst from https://docs.docker.com/desktop/release-notes/
and pass its local path with --docker-desktop-package when applying.
Zoom is installed from AUR with yay. If standalone docker-compose is installed,
--replace-compose explicitly permits replacing it with Docker Desktop's Compose plugin.
The script does not sign in to accounts or run Gentle AI's interactive installer.
Visual Studio Code is installed for the current user from Flathub using Flatpak.
DBeaver Community is installed from the official Arch repositories.
Obsidian is installed from the official Arch repositories.
rclone is installed from the official Arch repositories; cloud accounts are configured manually.
KIO GDrive is installed from the official Arch repositories for KDE access to Google Drive.
EOF
}
while (($#)); do
  case "$1" in
    --apply) apply=true; shift ;;
    --warp-package)
      if (($# < 2)); then usage >&2; exit 2; fi
      if [[ $warp_package_supplied == true ]]; then
        echo 'Specify --warp-package only once.' >&2
        exit 2
      fi
      warp_package_supplied=true
      warp_package=$2; shift 2 ;;
    --antigravity-archive)
      if (($# < 2)); then usage >&2; exit 2; fi
      if [[ $antigravity_archive_supplied == true ]]; then
        echo 'Specify --antigravity-archive only once.' >&2
        exit 2
      fi
      antigravity_archive_supplied=true
      antigravity_archive=$2; shift 2 ;;
    --docker-desktop-package)
      if (($# < 2)); then usage >&2; exit 2; fi
      if [[ $docker_desktop_package_supplied == true ]]; then
        echo 'Specify --docker-desktop-package only once.' >&2
        exit 2
      fi
      docker_desktop_package_supplied=true
      docker_desktop_package=$2; shift 2 ;;
    --replace-compose) replace_compose=true; shift ;;
    -h|--help) help_requested=true; shift ;;
    *) usage >&2; exit 2 ;;
  esac
done

if [[ $warp_package_supplied == true && ( ! -f $warp_package || $warp_package != *.pkg.tar.zst ) ]]; then
  echo 'The provided Warp package must be an existing local .pkg.tar.zst file.' >&2
  exit 2
fi
if [[ $antigravity_archive_supplied == true && ( ! -f $antigravity_archive || $antigravity_archive != *.tar.gz ) ]]; then
  echo 'The Antigravity archive must be an existing local .tar.gz file.' >&2
  exit 2
fi
if [[ $docker_desktop_package_supplied == true && ( ! -f $docker_desktop_package || $docker_desktop_package != *.pkg.tar.zst ) ]]; then
  echo 'The Docker Desktop package must be an existing local .pkg.tar.zst file.' >&2
  exit 2
fi
if [[ $help_requested == true ]]; then usage; exit 0; fi
if [[ ! -r /etc/os-release ]] || ! grep -q '^ID=arch$' /etc/os-release; then
  echo 'This installer supports Arch Linux only.' >&2
  exit 1
fi

cat <<'EOF'
Arch setup plan:
  1. sudo pacman -Syu --needed git github-cli opencode go nodejs npm piper openrgb discord coolercontrol
  2. sudo pacman -S --needed mpv clang cmake ninja
  3. Install the locally downloaded official Warp package with pacman -U.
  4. Install pinned Gentle AI and Engram from Go modules into ~/.local/bin.
  5. Download RTK v1.1.0 from its official release and verify SHA-256 before installation.
  6. Install Zoom from AUR using yay and Docker Desktop from a local official Arch package.
     Existing standalone docker-compose is replaced only with --replace-compose.
  7. Install Gemini CLI v0.66.0 from npm and Google Antigravity App from a local official archive.
  8. Register Engram with OpenCode and check the Gentle AI install plan.
  9. Finish Gentle AI selection and account sign-in manually; RTK hooks remain off.
  10. Install Visual Studio Code via Flatpak from the current user's Flathub remote.
  11. Install DBeaver Community from the official Arch repositories.
  12. Install Obsidian from the official Arch repositories.
  13. Install rclone from the official Arch repositories for cloud synchronization.
  14. Install KIO GDrive from the official Arch repositories for KDE cloud access.
  KDE appearance is separate: see kde.sh --help.
EOF
if [[ $apply == false ]]; then
  exit 0
fi
if [[ -z $warp_package || ! -f $warp_package || $warp_package != *.pkg.tar.zst ]]; then
  echo 'Provide a local Warp .pkg.tar.zst with --warp-package before applying.' >&2
  exit 2
fi
if [[ -z $antigravity_archive || ! -f $antigravity_archive || $antigravity_archive != *.tar.gz ]]; then
  echo 'Provide an official Linux x64 Antigravity .tar.gz with --antigravity-archive before applying.' >&2
  exit 2
fi
if [[ -z $docker_desktop_package || ! -f $docker_desktop_package || $docker_desktop_package != *.pkg.tar.zst ]]; then
  echo 'Provide an official Arch Docker Desktop .pkg.tar.zst with --docker-desktop-package before applying.' >&2
  exit 2
fi
if [[ $EUID == 0 ]]; then
  echo 'Run as your regular user; sudo is used only for pacman.' >&2
  exit 1
fi
if [[ $(uname -m) != x86_64 ]]; then
  echo 'This pinned RTK binary supports x86_64 only; no packages were installed.' >&2
  exit 1
fi
if [[ -e "$HOME/.local/opt/google-antigravity" ]]; then
  echo 'Antigravity installation already exists; refusing to overwrite it.' >&2
  exit 1
fi
command -v python3 >/dev/null || { echo 'Python 3 is required to validate the Antigravity archive.' >&2; exit 1; }
if ! python3 - "$antigravity_archive" <<'PY'
import posixpath
import sys
import tarfile

launcher_count = 0
try:
    with tarfile.open(sys.argv[1], 'r:gz') as archive:
        for entry in archive:
            name = entry.name.removeprefix('./')
            if not name or name.startswith('/') or '..' in name.split('/'):
                raise ValueError('unsafe member path')
            if name == 'Antigravity':
                launcher_count += 1
                if not entry.isfile():
                    raise ValueError('launcher is not a regular file')
            if entry.issym():
                target = entry.linkname
                resolved = posixpath.normpath(posixpath.join(posixpath.dirname(name), target))
                if not target or target.startswith('/') or resolved in ('..', '.') or resolved.startswith('../'):
                    raise ValueError('symlink escapes archive')
            elif not (entry.isfile() or entry.isdir()):
                raise ValueError('unsupported archive member')
    if launcher_count != 1:
        raise ValueError('expected one regular top-level launcher')
except (OSError, tarfile.TarError, ValueError) as error:
    print(f'Invalid Antigravity archive: {error}', file=sys.stderr)
    sys.exit(1)
PY
then
  exit 1
fi
for cmd in pacman sudo yay go; do
  # Go is installed in the first step; it need not exist yet.
  [[ $cmd == go ]] && continue
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
if ! package_info=$(LC_ALL=C pacman -Qip "$docker_desktop_package" 2>/dev/null) ||
   ! grep -Eq '^Name[[:space:]]*:[[:space:]]*docker-desktop[[:space:]]*$' <<<"$package_info" ||
   ! grep -Eq '^Architecture[[:space:]]*:[[:space:]]*x86_64[[:space:]]*$' <<<"$package_info"; then
  echo 'The local package must identify itself as Docker Desktop for x86_64.' >&2
  exit 2
fi
if pacman -Qq docker-compose >/dev/null 2>&1 && [[ $replace_compose != true ]]; then
  echo 'Standalone docker-compose is installed; pass --replace-compose to replace it with Docker Desktop Compose.' >&2
  exit 2
fi

sudo pacman -Syu --needed git github-cli opencode go nodejs npm piper openrgb discord coolercontrol
sudo pacman -S --needed mpv clang cmake ninja
sudo pacman -S --needed dbeaver
sudo pacman -S --needed obsidian
sudo pacman -S --needed rclone
sudo pacman -S --needed kio-gdrive
sudo pacman -S --needed flatpak
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user --assumeyes --noninteractive flathub com.visualstudio.code
sudo pacman -U "$warp_package"
yay -S --needed zoom
if pacman -Qq docker-compose >/dev/null 2>&1; then
  sudo pacman -R docker-compose
  if ! sudo pacman -U "$docker_desktop_package"; then
    echo 'Docker Desktop installation failed; restoring standalone docker-compose.' >&2
    if ! sudo pacman -S --needed docker-compose; then
      echo 'Restore docker-compose manually: sudo pacman -S docker-compose' >&2
    fi
    exit 1
  fi
else
  sudo pacman -U "$docker_desktop_package"
fi
mkdir -p "$HOME/.local/bin"
export GOBIN="$HOME/.local/bin"
go install github.com/gentleman-programming/gentle-ai/v4/cmd/gentle-ai@v4.3.1
go install github.com/Gentleman-Programming/engram/cmd/engram@v3.6.1
npm install -g @google/gemini-cli@0.66.0

# Do not run a downloaded shell installer or silently configure RTK hooks.
rtk_url='https://github.com/rtk-ai/rtk/releases/download/v1.1.0/rtk-x86_64-unknown-linux-musl.tar.gz'
rtk_sha256='9454ad1b9489daa57ab0a9f4ebe2faaf4dc82b8a0f26c9e5135151abd7c9378d'
for cmd in curl sha256sum tar install; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
rtk_stage=$(mktemp -d)
trap 'rm -rf -- "$rtk_stage"' EXIT
curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' "$rtk_url" --output "$rtk_stage/rtk.tar.gz"
printf '%s  %s\n' "$rtk_sha256" "$rtk_stage/rtk.tar.gz" | sha256sum --check -
tar -tzf "$rtk_stage/rtk.tar.gz" | grep -Fxq rtk
tar -xOf "$rtk_stage/rtk.tar.gz" rtk > "$rtk_stage/rtk"
test -s "$rtk_stage/rtk"
install -m 755 "$rtk_stage/rtk" "$GOBIN/rtk"
"$GOBIN/rtk" --version

mkdir -p "$HOME/.local/opt"
antigravity_stage=$(mktemp -d "$HOME/.local/opt/.google-antigravity.XXXXXXXX")
trap 'rm -rf -- "$rtk_stage" "$antigravity_stage"' EXIT
tar --no-same-owner --no-same-permissions -xzf "$antigravity_archive" -C "$antigravity_stage"
test -x "$antigravity_stage/Antigravity" || { echo 'Antigravity launcher is not executable.' >&2; exit 1; }
mv -- "$antigravity_stage" "$HOME/.local/opt/google-antigravity"
"$GOBIN/engram" setup opencode
"$GOBIN/gentle-ai" install --dry-run
cat <<'EOF'
Next: run ~/.local/bin/gentle-ai install to choose components interactively.
Then run ~/.local/bin/gentle-ai doctor and ~/.local/bin/engram doctor.
Authenticate GitHub yourself with gh auth login; never put credentials in this repo.
Start a new OpenCode session to check the Engram connection.
Launch the Antigravity App from ~/.local/opt/google-antigravity/Antigravity.
Docker Desktop is installed but not started; accept its terms yourself when launching it.
EOF
