# Arch workstation setup

A local-first bootstrap for Git, GitHub CLI, OpenCode v2, Gemini CLI, Google Antigravity App, Warp Terminal, Gentle AI, Engram, RTK, Piper, OpenRGB, Discord, Zoom, Docker Desktop, open-source CoolerControl, mpv, Clang, CMake, Ninja, and optional KDE appearance. **Nothing is published.**

## Quick path

1. Inspect the plan: `bash bootstrap.sh`.
2. Download Warp's **Arch Linux** package from [Warp's download page](https://www.warp.dev/download), the **Linux x64 Antigravity App** `.tar.gz` from [Google's download page](https://antigravity.google/download/), and the official **Arch Docker Desktop** `.pkg.tar.zst` from [Docker's release notes](https://docs.docker.com/desktop/release-notes/). Inspect the local packages before installing. Antigravity CLI (`agy`) and Antigravity IDE are different products and are not included.
3. Install and inspect the `yay` AUR helper before applying: the script uses it to install Zoom from AUR. On an Arch x86_64 machine, run `bash bootstrap.sh --apply --warp-package /path/to/warp-terminal.pkg.tar.zst --antigravity-archive /path/to/Antigravity.tar.gz --docker-desktop-package /path/to/docker-desktop-x86_64.pkg.tar.zst`. This upgrades installed Arch packages, installs Docker Desktop's dependencies, downloads Go modules and installs Gemini CLI v0.66.0 from npm; use it only when you intend those changes. The official Docker Desktop Arch package is marked experimental by its publisher.
4. If standalone `docker-compose` is installed, the script stops **before changing anything**. Inspect the impact, then rerun with `--replace-compose` if you agree to remove the standalone package and use Docker Desktop's `docker compose` plugin instead. The script attempts to restore the standalone package if Docker Desktop installation fails; inspect the result if restoration also fails. It does not start Docker Desktop or accept the [subscription agreement](https://www.docker.com/legal/docker-subscription-service-agreement) for you. Docker Desktop uses an isolated VM and context; existing Docker Engine images and containers do not move into it.
5. Follow the printed steps to run Gentle AI's interactive component installer, sign in to GitHub with `gh auth login`, and verify both doctors. Credentials, Git identity, OpenCode settings, and personal memory are deliberately **not** copied.
6. Optionally preview KDE changes with `bash kde.sh`, then apply with `bash kde.sh --apply` from a Plasma desktop session.

## Optional: Sweet folders with Candy icons

Preview with `bash sweet-folders.sh`, then apply with `bash sweet-folders.sh --apply` as your regular user. This selects purple folder icons from [Sweet-folders](https://github.com/EliverLara/Sweet-folders), inheriting [Candy](https://github.com/EliverLara/candy-icons) application icons. Missing themes are downloaded from pinned upstream commits and checked against recorded SHA-256 hashes (not independently signed upstream checksums). Existing theme installations are preserved. No sudo or upstream install scripts are used.

The script backs up an existing `~/.config/kdeglobals`, changes only its icon theme, and leaves panels, wallpaper, and window styling unchanged. It is independent of `bootstrap.sh` and `kde.sh`, so it also works with multiple panels. Reopen Dolphin if icons have not refreshed. To undo the selection, choose Candy or Breeze in System Settings > Colors & Themes > Icons, or restore the printed `kdeglobals` backup. Installed assets remain in `~/.local/share/icons/Sweet-Purple` and `candy-icons`.

Check without touching your desktop: `bash tests/sweet-folders-test.sh`.

## Optional: animated wallpaper (Plasma 6)

Preview with `bash wallpaper.sh`, then install with `bash wallpaper.sh --apply` as your regular user. This installs [Smart Video Wallpaper Reborn](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn) 2.16.0 from its official release using `kpackagetool6`, for your user only. The archive is checked against a pinned SHA-256 recorded from the release download, not an independently signed upstream checksum. An existing plugin installation is kept unchanged. This is separate from `bootstrap.sh` and `kde.sh`.

Plasma 6 and Arch's `qt6-multimedia` and `qt6-multimedia-ffmpeg` packages are required. If missing, the script stops and prints the dependency installation command; it never invokes sudo. Your current wallpaper, lock screen, and login screen are not changed.

To activate it, right-click the desktop → **Desktop and Wallpaper** → select **Smart Video Wallpaper Reborn** as the wallpaper type → add a local video → **Apply**. This plays video backgrounds; it does not provide Wallpaper Engine's Workshop catalog or all its interactive effects. Video playback can increase GPU usage and power consumption.

Run `bash tests/wallpaper-test.sh` for isolated mocked checks. To remove the user plugin, switch back to an image wallpaper first, then run `kpackagetool6 --type Plasma/Wallpaper --remove luisbocanegra.smart.video.wallpaper.reborn`.

## Optional: Plasma notification position

Preview with `bash notifications.sh`, then apply with `bash notifications.sh --apply` from your Plasma 6 session. This sets notification popups to the top right instead of beside the tray widget, without changing panels or per-application preferences. It backs up an existing `~/.config/plasmanotifyrc` and notifies Plasma of the setting change. It works independently of `kde.sh`, including on multi-panel desktops. Confirm the next popup stays inside the intended monitor; this does not force a particular monitor.

Run `bash tests/notifications-test.sh` for isolated mocked checks; it does not change your desktop.

## Optional: Zsh and Powerlevel10k

Preview the standalone terminal setup with `bash terminal.sh`, then run `bash terminal.sh --apply` as your regular user. It installs Arch's `zsh` and `ttf-meslo-nerd` packages using sudo, clones the pinned Powerlevel10k v1.20.0 tag from [the official repository](https://github.com/romkatv/powerlevel10k), adds its lean prompt configuration to `~/.zshrc`, and changes your login shell with `chsh`. Log out and back in afterward. This does not run as part of `bootstrap.sh` and does not require Warp, Docker Desktop, or Antigravity packages.

The script leaves an existing `~/.p10k.zsh` intact and appends a marked theme block to an existing `~/.zshrc` only once. It also keeps `~/.local/bin` and the existing NVM initialization available in Zsh. If you use Kitty, Konsole, or another terminal, select **MesloLGS Nerd Font Mono** as its font to display prompt icons correctly; the script does not rewrite terminal-emulator settings. Run `p10k configure` from Zsh later if you want to customize the default lean layout. Installing Arch packages requires working sudo authentication in your own terminal.

## DBeaver Community

DBeaver Community is installed by `bootstrap.sh --apply` from the [official Arch `dbeaver` package](https://archlinux.org/packages/extra/x86_64/dbeaver/). To install only the database client, preview `bash dbeaver.sh`, then run `bash dbeaver.sh --apply` as your regular user. This uses `sudo pacman -Syu --needed dbeaver`, which also upgrades installed Arch packages to avoid a partial upgrade; sudo authentication and package confirmation remain interactive.

Launch it from the application menu or run `dbeaver`. Create connections manually; no database server is installed and no connections or credentials are configured by these scripts. DBeaver may download a database driver when you first connect. Run `bash tests/dbeaver-test.sh` for mocked checks without installing packages.

## Obsidian

`bootstrap.sh --apply` installs Obsidian from the official Arch repositories. To install it separately, run `sudo pacman -Syu --needed obsidian`; this also upgrades installed packages to avoid a partial upgrade. Launch it from the application menu or run `obsidian`. Create or open your vault manually.

## Google Drive synchronization

`bootstrap.sh --apply` installs [rclone](https://rclone.org/drive/) from the official Arch repositories. To install it separately, run `sudo pacman -Syu --needed rclone`, which also upgrades installed packages. Configure Google Drive authorization yourself with `rclone config`; the bootstrap does not access your account or enable synchronization automatically. Bidirectional synchronization can propagate deletions: review the [bisync documentation](https://rclone.org/bisync/) and back up your data before configuring it.

The bootstrap also installs [KIO GDrive](https://apps.kde.org/kio_gdrive/) for accessing Google Drive in Dolphin. To install it separately, run `sudo pacman -Syu --needed kio-gdrive` (this also upgrades installed packages), then add your Google account in KDE System Settings under Online Accounts. KIO GDrive accesses files in the cloud; it does not automatically synchronize a local folder.

## Visual Studio Code
Visual Studio Code is also installed by `bootstrap.sh --apply`: it installs Flatpak with pacman, adds Flathub for the current user if absent, and installs `com.visualstudio.code` with its required runtimes. Existing installations are retained. Launch it from the application menu or with `flatpak run com.visualstudio.code`. This is the Flathub distribution, not an Arch-native package; its sandbox can affect access to host development tools.

To use Powerlevel10k in VS Code Flatpak, open VS Code once and create user settings, then preview `bash vscode-terminal.sh` and apply with `bash vscode-terminal.sh --apply`. This opt-in step adds a `zsh (host)` terminal profile using Flatpak's bundled `/app/bin/host-spawn` PTY bridge and `/usr/bin/zsh -l`, makes it the default, and selects **MesloLGS Nerd Font Mono**. Close any existing integrated terminal and open a new one. Do not use `flatpak-spawn --host` as the interactive shell launcher: its missing controlling PTY can break Backspace, Ctrl keys, and job control. Other VS Code settings and terminal profiles are preserved. The updater accepts strict JSON `settings.json` only; if you have JSONC comments or trailing commas, it refuses to rewrite the file and you must add the profile manually in VS Code settings.

## Optional: agent-browser

Preview with `bash agent-browser.sh`, then install for your user with `bash agent-browser.sh --apply`. This installs [agent-browser](https://github.com/vercel-labs/agent-browser) v0.41.2 from the public npm registry into `~/.local` and downloads its Chrome for Testing browser. Node.js 22+ is required. It does not need sudo, reuse npm credentials, or run npm lifecycle scripts. Add `~/.local/bin` to your `PATH` if necessary, then check `agent-browser --version` and try `agent-browser open https://example.com` followed by `agent-browser close`.

This opt-in step is separate from `bootstrap.sh`; no browser profile or account is connected automatically. It uses a separate browser session, not your existing Chrome sign-ins. Run `bash tests/agent-browser-test.sh` for mocked, offline installer checks.

## Optional: Hermes Agent (manual installation)

Hermes Agent is **not** installed by `bootstrap.sh`. On Arch Linux x86_64, the [official CLI installation guide](https://hermes-agent.nousresearch.com/docs/getting-started/installation) uses its source installer. Review the installer before running it; it downloads and prepares a separate Python/Node runtime and may install browser or computer-use components.

```bash
hermes_stage=$(mktemp -d)
curl -fsSL https://hermes-agent.nousresearch.com/install.sh -o "$hermes_stage/install.sh"
less "$hermes_stage/install.sh"
bash "$hermes_stage/install.sh"
rm -rf -- "$hermes_stage"
hermes doctor
```

Run this as your regular user, not with `sudo`. Follow the interactive setup for a model provider; never save API keys or the Hermes data directory in this repository. The default source checkout and data live under `~/.hermes/`, and the CLI launcher is `~/.local/bin/hermes`. See the official guide for installation options and updates; the AUR route is not officially supported.

## Cooling hardware

The Arch `coolercontrol` package supplies the open-source GUI and depends on the `coolercontrold` daemon. This bootstrap **does not enable or start the service, configure hardware permissions, or change fan curves**. Once installed, inspect the [hardware support guidance](https://docs.coolercontrol.org/getting-started/) before starting `sudo systemctl enable --now coolercontrold` on a machine with supported cooling channels. Missing PWM/fan readings may mean the hardware or driver cannot be controlled; never force a fan speed without confirming temperature and failsafe behavior.

## Safety and checks

The bootstrap defaults to a no-change plan and requires local Warp, Antigravity, and Docker Desktop packages before modifying anything. Python 3 is required **before applying** to validate archive paths and links. Antigravity is extracted into `~/.local/opt/google-antigravity/` without replacing a previous installation; its official download page does not publish a SHA-256 here, so verify the source and review the archive yourself. The Go module versions are pinned; review the upstream release and update those pins deliberately. RTK v1.1.0 is downloaded as the official Linux x86_64 release and checked against its published SHA-256 before installing the binary; this pinned step currently supports x86_64 only. RTK hooks are **not** enabled and its separate proxy is **not** installed. The script installs tools but does not sign in or silently overwrite existing OpenCode preferences. KDE customization is separate and opt-in. Piper and OpenRGB are installed as applications only: no mouse daemon, hardware permissions, RGB device rules, or services are enabled automatically. Discord and Zoom sign-in are manual. Docker Desktop's package modifies `/etc/hosts` and enables capabilities for its backend; the bootstrap does not enable its service or change the pre-existing Docker Engine service.

Run `bash tests/bootstrap-test.sh`, `bash tests/kde-test.sh`, `bash tests/terminal-test.sh`, `bash tests/terminal-chsh-failure-test.sh`, `bash tests/vscode-terminal-test.sh`, and `bash tests/vscode-terminal-symlink-test.sh` for mocked checks; none installs packages or modifies your KDE, shell, or VS Code settings. For a real installation, check `opencode --version`, `warp-terminal`, `gentle-ai doctor`, and `engram doctor` in a new OpenCode session.

Upstream: [OpenCode v2 installation](https://opencode.ai/v2/docs/), [Gemini CLI installation](https://geminicli.com/docs/get-started/installation/), [Google Antigravity download](https://antigravity.google/download/), [Warp installation](https://docs.warp.dev/getting-started/quickstart/installation-and-setup/), [Gentle AI releases](https://github.com/Gentleman-Programming/gentle-ai/releases), [Engram releases](https://github.com/Gentleman-Programming/engram/releases), [RTK release](https://github.com/rtk-ai/rtk/releases/tag/v1.1.0).
# Arch-Linux-Config
