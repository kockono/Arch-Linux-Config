# Transcribe desktop audio locally

Install the pinned [CGAlei/FasterWhisper](https://github.com/CGAlei/FasterWhisper) capture module and faster-whisper engine without changing NVIDIA drivers or system Python.

```bash
bash fasterwhisper.sh           # Preview; changes nothing
bash fasterwhisper.sh --apply   # Download Python, dependencies and multilingual base model
~/.local/bin/arch-fasterwhisper --check
~/.local/bin/arch-fasterwhisper --sources
~/.local/bin/arch-fasterwhisper --listen --language es
```

Press **Ctrl+C** to stop. Nothing starts automatically. The default source follows your current output at launch, including Bluetooth headphones. Choose another output explicitly with `--source NAME.monitor`. There is no microphone fallback.

For Discord, this captures everything played on that output, including other apps. It is not per-speaker separation or a Discord bot. Tell participants before transcribing a call. Headset/output changes during capture require stopping and relaunching.

## What is installed

- Private Python 3.11.14, uv 0.9.11 and hash-locked Python dependencies under `~/.local/share/arch-setup/fasterwhisper` (or `$XDG_DATA_HOME/arch-setup/fasterwhisper`).
- Upstream source at commit `513c15d1fd3910f38ebcf435af681a01105a740a`; archives are checksum-verified. No upstream installation script is executed.
- Multilingual `base` model pinned to Hugging Face revision `ebe41f70d5b6dfa9166e2c581c45c9c0cfc57b66`.
- An integration launcher using upstream `AudioCapture` with a bounded buffer and a local CPU/int8 engine. It intentionally replaces upstream's interactive WebSocket client, clipboard copying, global process killing and optional LLM processing.

Installation needs network access to GitHub, Python package hosting and Hugging Face. Transcription thereafter uses local model files, without an API key or transcript uploads. Output goes only to the terminal unless you redirect it. No OpenRouter refinement or WebSocket server is started.

## Requirements and limits

Linux x86_64, Python 3 for preflight, curl, tar, sha256sum, libportaudio, `pactl` and `parec`. On Arch, the latter tools are provided by `libpulse`. The script never invokes sudo. Private Python avoids compatibility issues with the system Python version.

CPU mode avoids CUDA changes on Pascal GPUs such as GTX 1070; GPU acceleration is not configured. Live latency depends on CPU load. Audio is processed in chunks and the bounded queue can discard older audio under overload. This is not a lossless meeting recorder or word-perfect transcription.

Use `--file recording.wav --language en` for an existing recording, or `--language auto` for automatic language detection. `--help`, `--sources` and `--check` never record audio. `--check` loads the model but does not prove real-time performance.

`--source` is only valid with `--listen`; `--language` is only valid with `--listen` or `--file`. Incompatible explicit options are rejected before loading the model.

Reapplying preserves an identical managed installation and checks it. Conflicting or incomplete targets are left untouched for manual inspection. There is no automatic upgrade/removal. To uninstall, first stop capture, then remove only the managed installation directory and `~/.local/bin/arch-fasterwhisper`; your audio configuration and model source files elsewhere remain unchanged.
