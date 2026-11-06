#!/usr/bin/env bash
set -euo pipefail
usage() { echo 'Usage: bash fasterwhisper.sh [--apply]  # preview or install local-only CPU transcription'; }
if (($# > 1)); then usage >&2; exit 2; fi
case "${1:-}" in
  '') echo 'Plan: install pinned CGAlei/FasterWhisper, private Python 3.11, CPU/int8 base model and arch-fasterwhisper. No sudo, drivers, autostart or audio capture.'; exit 0 ;;
  -h|--help) usage; exit 0 ;;
  --apply) ;;
  *) usage >&2; exit 2 ;;
esac
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root="${XDG_DATA_HOME:-$HOME/.local/share}/arch-setup/fasterwhisper"
launcher="$HOME/.local/bin/arch-fasterwhisper"
for tool in curl tar sha256sum python3 pactl parec; do
  command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }
done
[[ $(uname -sm) == 'Linux x86_64' ]] || { echo 'This pinned installer supports Linux x86_64 only.' >&2; exit 1; }
python3 -c 'import ctypes; ctypes.CDLL("libportaudio.so.2")' || { echo 'PortAudio is required; install it using your system package manager.' >&2; exit 1; }
test -s "$repo/fasterwhisper/requirements.lock" || { echo 'Missing dependency lock.' >&2; exit 1; }
if [[ -e $root || -L $root || -e $launcher || -L $launcher ]]; then
  if [[ -f $root/installed && -x $launcher ]] && cmp -s "$repo/fasterwhisper/transcribe.py" "$root/transcribe.py" && cmp -s "$repo/fasterwhisper/requirements.lock" "$root/requirements.lock"; then
    "$launcher" --check
    echo 'Existing managed installation preserved.'
    exit 0
  fi
  echo 'An existing or incomplete installation occupies the target. Preserving it; inspect before reinstalling.' >&2
  exit 1
fi
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
fetch() {
  curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' "$1" -o "$2"
  printf '%s  %s\n' "$3" "$2" | sha256sum --check --strict
}
fetch 'https://github.com/astral-sh/uv/releases/download/0.9.11/uv-x86_64-unknown-linux-gnu.tar.gz' "$stage/uv.tar.gz" '817c0722b437b4b45b9a7e0231616a09db76bab1b8d178ba7a9680c690db19f0'
fetch 'https://codeload.github.com/CGAlei/FasterWhisper/tar.gz/513c15d1fd3910f38ebcf435af681a01105a740a' "$stage/source.tar.gz" '5ba8a538026e343e0f0fc3eec4fcff3baf5f756f77c3b4129df9e641aa4822ad'
tar -xzf "$stage/uv.tar.gz" -C "$stage"
mkdir -p "$(dirname "$root")"
mkdir "$root"
mkdir "$root/tools"
cp "$stage/uv-x86_64-unknown-linux-gnu/uv" "$root/tools/uv"
mkdir "$root/source"
tar -xzf "$stage/source.tar.gz" -C "$root/source" --strip-components=1
export UV_PYTHON_INSTALL_DIR="$root/python" UV_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/arch-setup/uv"
export UV_PYTHON_PREFERENCE=only-managed UV_PYTHON_INSTALL_BIN=0
"$root/tools/uv" python install 3.11.14 --no-bin
"$root/tools/uv" venv --python 3.11.14 "$root/venv"
"$root/tools/uv" pip sync --python "$root/venv/bin/python" --require-hashes "$repo/fasterwhisper/requirements.lock"
export HF_HUB_DISABLE_TELEMETRY=1
"$root/venv/bin/python" - "$root/model" <<'PY'
import sys
from huggingface_hub import snapshot_download
snapshot_download('Systran/faster-whisper-base', revision='ebe41f70d5b6dfa9166e2c581c45c9c0cfc57b66',
                  local_dir=sys.argv[1], allow_patterns=['config.json', 'model.bin', 'tokenizer.json', 'vocabulary.txt'])
PY
cp "$repo/fasterwhisper/transcribe.py" "$repo/fasterwhisper/requirements.lock" "$root/"
mkdir -p "$(dirname "$launcher")"
{
  printf '#!/usr/bin/env bash\nset -euo pipefail\n'
  printf 'export ARCH_FASTERWHISPER_HOME=%q\n' "$root"
  printf 'export HF_HUB_OFFLINE=1 HF_HUB_DISABLE_TELEMETRY=1 LLM_ENABLED=false\n'
  printf 'exec %q %q "$@"\n' "$root/venv/bin/python" "$root/transcribe.py"
} > "$launcher"
chmod 755 "$launcher"
"$launcher" --check
printf '%s\n' 'source=513c15d1fd3910f38ebcf435af681a01105a740a' 'python=3.11.14' > "$root/installed"
echo "Installed: $launcher --listen --language es (explicit recording; Ctrl+C stops)."
