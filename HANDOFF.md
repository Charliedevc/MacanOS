# MacanOS v0.7.1 handoff

Recorded 2026-11-23T17:35:29-05:00.

- Workspace `C:\Users\Owner\Documents\MacanOS`, branch `macanos/v0.7`, tracking `origin/macanos/v0.7`. The verified v0.7.1 implementation checkpoint is `1f91338`, following v0.7.0 checkpoint `f47615d`.
- v0.7.1 remains the verified baseline. The architecture vision and Debian engineering-tool investigation are complete. No new application milestone is in progress.
- The isolated `restored-v0.6` checkout, the pre-existing `docs/FigCraft/` export and `docs/MacanOS-v0.7-integration-plan.md` are intentionally outside this checkpoint. Builds and raw evidence are ignored.
- No global settings or skills were changed. Repository instructions are unchanged at 801 characters. Validated environment-specific lessons are recorded in the [v0.7.1 validation report](docs/VALIDATION-v0.7.1.md).
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

The [architecture vision](docs/ARCHITECTURE-VISION.md) describes the proposed
offline-first onboard platform. This documentation update starts no development
milestone and leaves the GPU diagnostic as the next engineering task.

The single-client D3D12 diagnostic is complete. The unchanged v0.7.1 driver
registered and rendered with Qt Quick software and default OpenGL (llvmpipe).
Forced Intel Iris Xe D3D12 OpenGL crashed with SIGSEGV before registration
under both confirmed Qt render loops. A standalone Qt Quick window with no
MacanOS code also crashed under both D3D12 loops. The cause has been narrowed
to the graphics path, but the faulty component is still unknown.

The [validation report](docs/VALIDATION-v0.7.1.md) has startup results, frame
counts and local evidence paths. Preserve the software launcher. There is no
verified GPU FPS result, and sustained 60 FPS remains open.

## Debian engineering tools follow-up

- Installed and verified GDB 16.3 (`16.3-1`). The minimal Qt Quick probe
  exited normally with llvmpipe and produced 191 frame swaps. Both D3D12
  render loops reproduced SIGSEGV in `std::string::_M_assign`, called
  through Intel's `libigc.so` with Intel's `libLLVM-9.so` and
  `libigd12um64xel.so` on the same stack. This localizes the failure to a
  call path through Intel's WSL graphics compiler and driver. The Intel
  frames lack function symbols, so the exact defect remains unknown.
  Logs are in `artifacts/v0.7.1/gdb.JWchTOa4/`. Rerun with
  `sh artifacts/v0.7.1/qt-render-probe/run-gdb.sh` from the Debian repo root.
- Installed and verified Cppcheck 2.17.1 (`2.17.1-2`). The raw compile
  database referenced unbuilt Qt-generated MOC sources. A filtered copy
  analyzed eight compile entries across seven authored C++ files with Qt
  rules and warning, performance, and portability checks. It reported seven
  performance suggestions about returning or passing Qt values by reference,
  no error, warning, or portability diagnostics, and notices that normal
  analysis limits branch coverage. Treat the suggestions as review items.
  Evidence is in `artifacts/v0.7.1/cppcheck-initial.log`. Rerun after
  configuring `build-cppcheck` with `CMAKE_EXPORT_COMPILE_COMMANDS=ON`,
  then run `bash artifacts/v0.7.1/run-cppcheck.sh`.
- Existing coordinator and layout suites passed via CTest, 2/2. The Python
  process suite was preserved and was not rerun for this tooling-only work.
  Application source, build and test configuration, and graphics settings
  were preserved.

The minimal-probe backtrace task listed in the roadmap is complete. Before
any graphics change, capture the host Intel driver version and identify an
approved update or rollback candidate. After any approved change, rerun the
same minimal probes before testing the two-window GPU path.
