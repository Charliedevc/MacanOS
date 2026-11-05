# MacanOS v0.6 validation

Date: 2026-11-05. Platform: Debian 13 x86_64, GCC 14.2, CMake 4.4.4, Ninja 1.13.2, Qt 6.8.2. GUI rendering used `QT_QPA_PLATFORM=offscreen` and the Qt Quick software backend. These are executable desktop simulator results, not original v0.5 or vehicle results.

## Actual final results

| Check | Executed result |
|---|---|
| CMake configure and C++17 build | Passed; client, server, coordinator library and two QtTest targets built. |
| Coordinator QtTest suite | 12 test methods passed; 14 reported passes including initialization/cleanup; no failures/skips. |
| QML layout QtTest suite | Six role/resolution cases passed; eight reported passes including initialization/cleanup. Actual mouse clicks selected apps; all visible action targets were at least 44 DIP and inside the window; primary panel width was checked. |
| Multi-process Python suite | 12 tests passed in 44.196 seconds; actual server and frontend executables, no mock frontend. |
| Python compilation and shell syntax | Passed for supplied Python scripts/tests and `scripts/check.sh`. |
| Screenshots | Ten actual Qt `grabWindow()` captures, including both roles for all three modes, unified media, and two additional passenger resolutions. |
| Existing v0.5 tests | **Blocked:** source, test suite and recorded commit absent from the supplied repository. No regression success claimed. |
| Android, ARM64 or physical hardware tests | **Not executed:** no Android toolchain/device or ARM64 target, physical head unit, two outputs or touch controllers. |

There are **30 final test cases excluding Qt initialization/cleanup**: 12 coordinator + six layout cases + 12 process cases. The raw logs and machine-readable summary are in `docs/test-results/`.

Coordinator coverage includes all directed mode transitions, mode persistence, explicit resume after loss, expiry, output availability, role ownership, distinct output requirements, mixed dimensions/scales, bezel offsets, calibrated touch, transition-generation rejection, renderer limits, scheduled transitions, corrupt/unwritable settings, geometry-change fallback and shared-focus persistence.

Process coverage includes all six directed transitions with unchanged backend PID/session, independent app state, shared focus, synchronized media and driver-approved destinations, output-presence simulation, passenger process termination, driver-process shutdown, survivor operation, reconnect, backend silence/restart, retained mode settings, prohibited commands, duplicate-role rejection, timing estimates, 1920×720 and 1920×1080 passenger viewports, touch-coordinate protocol and offline initial startup. Recovered displays require explicit resume after a live session loss. Backend restart instead reloads saved settings when both clients register.

Clock evidence records each client's measured half-RTT uncertainty and the same transition schedule/session. It is not a frame-lock or real-panel latency measurement. State files are sampled independently; their timestamps need not be identical. Screenshots are sequential captures, not proof of simultaneous physical refresh.

## Failures found and fixed

The initial real-process run passed seven of nine tests and failed two: tests observed command-file consumption before the backend's response and state propagation. The client now records acknowledged command results and the harness waits for them. Successful heartbeat replies no longer erase visible operation errors. Both failures passed in subsequent runs; the initial failure log is retained as `initial-failures-resolved.log`.

Visual inspection also found a collapsed navigation panel caused by layout minimum sizing. Explicit side-column constraints fixed it. Qt layout tests now assert that the primary panel stays usable and that touch targets remain visible, bounded and at least 44 DIP across the six tested role/resolution combinations.

Other hardening includes duplicate-owner rejection, stale-generation touch rejection, affine pixel-centre mapping at rotated display edges, explicit resume after geometry changes, bounded JSON frames/output queues and peer count, cleanup of signal connections at server exit, and local ownership validation before backend actions.

The development host initially lacked CMake/Ninja and Qt headers. CMake/Ninja were installed into a workspace prefix; matching Debian Qt development packages were downloaded/extracted into another workspace prefix, using the installed matching runtime. Initial configure failures for missing runtime/OpenGL links were corrected in that local prefix. Nothing was installed into the host's system directories.

Final configuration emitted optional XKB and QML static-plugin link-target warnings due to that extracted development prefix. Dynamic QML runtime imports succeeded; all GUI tests and screenshots executed without ReferenceError, TypeError, binding-assignment or engine-load errors. Runtime tests establish successful software rendering only. The standard Debian dependency installation in the README avoids relying on the workspace-specific toolchain paths.

## Limitations and unfinished integration

- `cefde60` contains reconstructed reports only. The missing original v0.5 UI, SQLite trips, map/routing, real audio adapter and read-only diagnostic enforcement have not been modified or tested. This module does not prove preservation of those features.
- Its JSON TCP protocol is local to this module; an adapter to the actual OCTAVE API remains to be implemented against recovered source. There is no WebSocket transport here.
- All route, GPS, trip and vehicle figures are fixtures; the map is an original schematic. Shared destination approval is functional simulation, not tested turn-by-turn navigation. Media playback synchronizes state but produces no audible output.
- Mode settings and local app choices persist; fixture navigation/media state resets with backend restart. v0.5 SQLite or media persistence is not implemented by this module.
- Physical Qt screen selection/removal hooks are prepared. Output disappearance was simulated through the presence file; actual connector removal, compositor behavior, hardware DPI and touch routing are unverified.
- Logical canvas clipping duplicates scene rendering in each client. No GPU, thermal, refresh-phase or sustained performance benchmark was executed. There is no guarantee of visually seamless panel color, geometry or timing.
- Simulator sizes are not NaviRider specifications. Android secondary display/presentation/HOME APIs were researched, not executed. No APK or launcher was built.
- Factory Porsche systems, controls, electrical interfaces, security and vehicle modules were not accessed. Backend vehicle commands are absent and unknown operations are denied. Existing v0.5 restrictions must be regression-tested after source restoration.

## Recommended next milestone

Recover the actual v0.5 source checkout or Git bundle, establish a passing baseline, embed one coordinator into its backend and reuse its real navigation/media services. Then test an authorized Android device exposing two independent displays before evaluating any NaviRider purchase. Keep the original vehicle and factory control interfaces outside this work.
