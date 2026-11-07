# Optional agent-browser on Arch Linux
Install agent-browser for the current user and add an independently runnable setup path.
Branch: `feat/fasterwhisper` (existing dirty worktree); strategy: ask-on-risk; forecast: ~140 authored lines; runner: Bash mocked tests and live CLI.

## Specs
- S1: User request: “podriamos istalar agent browser  mejor y anexalo a @proyectos/arch-setup/”. Install the official Linux agent-browser CLI locally and provide an opt-in setup in this repository, without disturbing unrelated changes.
- S2: User authorization: “si autorizo”. Downloads may use the public npm registry and Google's Chrome for Testing distribution without credentials; no other remote destination is authorized. Verify the installed CLI and browser where possible.
- S3: Preserve existing bootstrap defaults and worktree changes. Document the preview, application and verification commands; test offline behavior with mocked dependencies.

## Tasks
- T1 (S1-S3): inline; complete; commit: this work-unit commit. Added isolated installer, tests and docs; installed and verified locally.

## Log
- L1: podriamos istalar agent browser  mejor y anexalo a @proyectos/arch-setup/
- L2: si autorizo
- L3: The worktree already has unrelated README edits and untracked wallpaper/sweet-folders files. Do not stage or modify those unrelated changes. High-risk item 5: installer and download behavior.
- L4: RED: installer was absent (exit 127). GREEN: `bash tests/agent-browser-test.sh`, `bash tests/bootstrap-test.sh`, and `bash tests/terminal-test.sh` passed; `bash -n agent-browser.sh tests/agent-browser-test.sh` and `git diff --check` passed. The local CLI reported 0.41.2 and Chrome 157.0.8103.38; open/snapshot/close on a data URL succeeded. Independent verifier found two security/version blockers; both were fixed and passed one targeted recheck. Existing README changes are left unstaged.
