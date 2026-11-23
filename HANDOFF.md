# MacanOS v0.7.1 handoff

Recorded 2026-11-23T16:26:42-05:00.

- Workspace `C:\Users\Owner\Documents\MacanOS`, branch `macanos/v0.7`, with no upstream configured. The commit containing this handoff is the local v0.7.1 checkpoint. Its predecessor is the verified v0.7.0 checkpoint `f47615d`.
- Objective is to finish and preserve v0.7.1. The FigCraft reference, reusable QML, destination filtering, display inventory, explicit recovery, and connected-client socket teardown fix are included.
- The isolated `restored-v0.6` checkout, the pre-existing `docs/FigCraft/` export and `docs/MacanOS-v0.7-integration-plan.md` are intentionally outside this checkpoint. Builds and raw evidence are ignored.
- No global settings or skills were changed. The new repository instructions are in `AGENTS.md`. Validated environment-specific lessons are recorded in the [v0.7.1 validation report](docs/VALIDATION-v0.7.1.md).
- Checkpoint validation passed all 35 cases, and both WSLg clients completed Independent, Shared, and Unified. Repeated software measurements were 56.54 / 56.55 FPS at 1280 × 480 and 58.79 / 58.78 FPS at 1024 × 360, driver then passenger. The new `AGENTS.md` is 801 characters.

## Reproduce

Run from the repository directory in Debian WSL2. Toolchain versions and results are recorded in the validation report.

```sh
sh scripts/check.sh
evidence=$(mktemp -d)
QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
  python3 scripts/measure-rendering.py --output "$evidence"
```

The shell check saves evidence in a fresh ignored directory under `artifacts/`. Use the [README](README.md) for interactive launch. Keep runtime state on Debian-local storage for timing runs.

## Resume point

The single-client D3D12 diagnostic is complete. The unchanged v0.7.1 driver
registered and rendered with Qt Quick software and default OpenGL (llvmpipe).
Forced Intel Iris Xe D3D12 OpenGL crashed with SIGSEGV before registration
under both confirmed Qt render loops. A standalone Qt Quick window with no
MacanOS code also crashed under both D3D12 loops. The cause has been narrowed
to the graphics path, but the faulty component is still unknown.

The [validation report](docs/VALIDATION-v0.7.1.md) has startup results, frame
counts and local evidence paths. The next task after authorization is to
collect a symbolized backtrace from the minimal Qt program, as specified in
[ROADMAP.md](ROADMAP.md). Preserve the software launcher. There is no verified
GPU FPS result, and sustained 60 FPS remains open. No application source or
system graphics settings were changed during the diagnostic.
