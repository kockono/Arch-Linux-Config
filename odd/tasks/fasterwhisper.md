# Isolated FasterWhisper installation
Install the requested application locally and provide an optional reproducible installer.
Branch: `feat/fasterwhisper`; strategy: ask-on-risk; forecast: ~350 authored lines plus generated lock; tests: Python unittest and shell tests.

## Specs
- S1: “ok mete fasterwhisper istalalo y anexalo al repo de @proyectos/arch-setup/” — install CGAlei/FasterWhisper locally and include installer, checks and usage in this repository. Verify imports and actual inference without capturing a call.
- S2: Context: “ok necesito que istalemos un escuchador de audio por llama ejemplo discord” — provide explicit monitor-source capture for desktop audio. Assumption: CPU/int8 first, no automatic listening, no remote transcript processing, no changes to NVIDIA drivers.

## Tasks
- T1 [S1,S2] inline, verified: pinned optional installer, managed environment, safe launcher, tests and documentation; 9 tests GREEN after initial RED and blocker-specific RED. Commit pending. Writer trigger absent. Risk: item 5 (installation/dependencies).
- T2 [S1,S2] delegated command execution, verified: private install and 27-package hash lock; actual base-model file inference succeeded; second apply preserved 8605 files. Long install per-action trigger. Risk: item 5.
- T3 [S1,S2] independent verification, verified: installation safety, user-state preservation and regression tests; named item 5. Initial two blockers corrected together and scoped recheck passed. Commit pending.

## Log
- L1: User request verbatim: “ok mete fasterwhisper istalalo y anexalo al repo de @proyectos/arch-setup/”
- L2: Baseline `5b81c17428b605a0bd840f2ee9217e4b5b7d6b54`. Existing dirty README and untracked wallpaper/sweet-folders files belong to previous work and will not be committed here. Add dedicated docs rather than including unrelated README changes.
- L3: Upstream commit `513c15d1fd3910f38ebcf435af681a01105a740a`. Its launcher hardcodes another home directory and uses broad pkill. Use an owned-process launcher instead; disable LLM refinement, clipboard copying and autostart. No real audio capture during installation checks.
- L4: Engram resolved project `arch-linux-config`, but scoped search returned unknown_project. Mirror pending; do not substitute a different project key. CodeGraph absent; filesystem fallback used.
- L5: CPU/int8 inference on public whisper.cpp `samples/jfk.wav`, revision `b0a11594aec50892a02cd8d129eee2dfe93a8bb8`, SHA256 `59dfb9a4acb36fe2a2affc14bacbee2920ff435cb13cc314a08c13f66ba7860e`, returned recognizable speech in 1.607s. No real audio captured; live performance untested. Parent reran installed `--check` successfully.
- L6: All 9 existing shell suites passed in an isolated copy (bootstrap, kde, notifications, sweet-folders, terminal/chsh-failure, vscode-terminal/symlink and wallpaper). No shared existing code changed; differential command comparison is not applicable.
- L7: Independent verification found silent acceptance of incompatible runtime options and a non-retryable root left after bad checksum. Added regression tests (observed RED), fixed both together, 9 tests GREEN; independent scoped recheck passed including both archive failures. Parent re-ran installed model check and public sample inference after deploying the corrected launcher.
- L8: Rollback boundary is only the new FasterWhisper installer, integration directory, focused test, dedicated documentation and task log; no existing README/script edits. Local installation can be removed independently after stopping capture. Native candidate assessment pending; no push or PR authorized.
