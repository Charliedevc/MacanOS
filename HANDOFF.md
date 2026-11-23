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

The exact next task, after approval to continue beyond this checkpoint, is the D3D12 startup diagnostic in [ROADMAP.md](ROADMAP.md). Start with one unchanged v0.7.1 client and confirm registration and rendering before starting a pair. Preserve the software path. There is no verified GPU FPS result and sustained 60 FPS is open. The display coordinator and baseline archives remain authoritative.
