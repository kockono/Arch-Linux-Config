#!/usr/bin/env python3
"""Local-only desktop transcription using CGAlei's capture module."""
import argparse
from collections import deque
import os
from pathlib import Path
import signal
import subprocess
import sys
import threading
import time


def pulse(*args):
    return subprocess.check_output(['pactl', *args], text=True, timeout=5).strip()


def resolve_source(selected):
    sources = {line.split()[1] for line in pulse('list', 'short', 'sources').splitlines() if len(line.split()) >= 2}
    source = selected or pulse('get-default-sink') + '.monitor'
    if not source.endswith('.monitor') or source not in sources:
        raise ValueError('Select an available output monitor with --source; microphone fallback is disabled.')
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--listen', action='store_true', help='Explicitly start desktop-audio capture; Ctrl+C stops it')
    mode.add_argument('--sources', action='store_true', help='List audio sources without recording')
    mode.add_argument('--check', action='store_true', help='Load the installed CPU model without recording')
    mode.add_argument('--file', type=Path, help='Transcribe an existing audio file without recording')
    parser.add_argument('--source', help='Exact PulseAudio monitor name; default follows the current output')
    parser.add_argument('--language', help='Spoken-language code, or auto (default: es)')
    args = parser.parse_args()
    if args.source is not None and not args.listen:
        parser.error('--source requires --listen')
    if args.language is not None and not (args.listen or args.file):
        parser.error('--language requires --listen or --file')
    args.language = args.language or 'es'
    if args.sources:
        print(pulse('list', 'short', 'sources'))
        return
    source = resolve_source(args.source) if args.listen else None
    root = Path(os.environ['ARCH_FASTERWHISPER_HOME'])
    sys.path.insert(0, str(root / 'source'))
    from faster_whisper import WhisperModel
    model = WhisperModel(str(root / 'model'), device='cpu', compute_type='int8', local_files_only=True)
    if args.check:
        from audio_capture import AudioCapture  # Verify the upstream integration without opening a device.
        print('Ready: CGAlei/FasterWhisper, multilingual base, CPU/int8; no audio captured.')
        return

    def transcribe(audio):
        segments, _ = model.transcribe(audio, language=None if args.language == 'auto' else args.language,
                                      beam_size=1, vad_filter=True)
        for segment in segments:
            print(segment.text.strip(), flush=True)

    if args.file:
        transcribe(str(args.file))
        return
    import numpy as np
    from audio_capture import AudioCapture
    running = threading.Event()
    running.set()
    chunks = deque(maxlen=160)
    capture = AudioCapture({'audio_source': source, 'sample_rate': 16000, 'quiet_mode': True}, chunks, running)
    signal.signal(signal.SIGTERM, lambda *_: running.clear())
    thread = capture.start()
    print(f'Listening to {source}. Local only; Ctrl+C stops capture. Slow inference can skip older audio.', flush=True)
    try:
        while running.is_set():
            time.sleep(5)
            if not thread.is_alive() or not running.is_set():
                raise RuntimeError('Audio capture stopped; no fallback device was opened.')
            with capture.buffer_lock:
                audio = np.concatenate(list(chunks)).flatten() if chunks else None
                chunks.clear()
            if audio is not None:
                transcribe(audio)
    except KeyboardInterrupt:
        pass
    finally:
        running.clear()
        capture.stop()
        thread.join(timeout=3)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, OSError, KeyError) as error:
        print(f'Error: {error}', file=sys.stderr)
        sys.exit(1)
