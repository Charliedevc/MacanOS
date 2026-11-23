# MacanOS v0.7.1 desktop validation

## Baseline and visual comparison

The fresh v0.7.0 build passed all 34 cases before local checkpoint `f47615d`.
That checkpoint includes the source, validation report, curated screenshots,
and native FigCraft file. The restored v0.6 checkout, prior investigation files,
builds, and temporary evidence remain outside the checkpoint.

All seven FigCraft pages and 19 top-level frames were exported with FigCraft CLI
from the native file and inspected against the simulator. The implementation
comparison follows the [design handoff](MacanOS-v0.7-design-to-qml.md).

| Design page | v0.7.1 implementation and remaining scope |
| --- | --- |
| Design System | Existing near-black palette and rose accent, reusable bordered panels and captions, matching album artwork treatment, 48 DIP controls, press feedback and accessible labels. |
| Independent Mode | Driver telemetry and large route area remain dominant. Navigation has a lower route card with fixture distance, ETA and GPS. The wide and 1024 DIP passenger media pages show media and route side by side. The 640 DIP layout prioritizes media and preserves separate Navigation access. CarPlay remains a design concept. |
| Shared Mode | Passenger can filter the three existing fixture destinations and propose a result. Drivers see matching proposal and approval controls, while the active schematic route remains visible. There is no arbitrary address lookup or passenger cancellation command. |
| Unified Mode | Navigation preserves the shared viewport and bezel geometry. Media retains the continuous fixture waveform with screen-local artwork, track metadata, and playback and next-track controls. The design's media library and queue remain outside the simulator's data model. |
| Android App Launcher | Design reference only. No Android packages or app launch integration were introduced. |
| Settings and Display Management | The Displays control opens a live, read-only inventory with detected simulator viewports, current mode, eligibility, and bezel information. Physical assignment and calibration remain unverified. |
| Recovery and Error States | Loading, stale/offline, and recovered views use native Qt Quick motion and persistent text. A recovered pair can explicitly resume the saved coordinated mode. App-specific errors belong to the deferred Android scope. |

The mode transition keeps the coordinator's scheduled cut. Once the transition
expires, the client stops evaluating its QML progress from the 16 ms clock signal.
Visible waveform bars use transforms with stable item geometry, and the hidden
panorama releases the media delegates. Reduced motion disables decorative
movement. The new connected-client regression exposed a teardown crash, which
was fixed by disconnecting socket callbacks before member destruction. No
coordinator, server, or fixture command behavior was changed.

## Build, tests, and screenshots

Debian 13.5 WSL2, Qt 6.8.2, GCC 14.2.0, CMake 3.31.6, Ninja 1.12.1,
Python 3.13.5, and a Ninja `RelWithDebInfo` build.

| Automated coverage | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| Existing coordinator cases | 12 | 0 | 0 |
| Existing responsive layout cases, extended to open and close Displays | 10 | 0 | 0 |
| Existing real-process cases | 12 | 0 | 0 |
| New connected-client destination and recovery case | 1 | 0 | 0 |
| **Total** | **35** | **0** | **0** |

The checkpoint rerun passed all 35 cases. The real-process suite took 43.540
seconds. Qt initialization and cleanup are
excluded. The new case verifies a live bezel value, Escape, keyboard focus,
destination filtering, delivery of the selected fixture to the backend, and
explicit resumption after a simulated display loss. It launches the actual C++
server and uses the passenger QML window with QtTest.

| Running simulator | Driver | Passenger |
| --- | --- | --- |
| Independent | [Driver](screenshots/v0.7.1/independent-driver.png) | [Passenger](screenshots/v0.7.1/independent-passenger.png) |
| Shared | [Driver](screenshots/v0.7.1/shared-driver.png) | [Passenger](screenshots/v0.7.1/shared-passenger.png) |
| Unified navigation | [Driver](screenshots/v0.7.1/unified-driver.png) | [Passenger](screenshots/v0.7.1/unified-passenger.png) |
| Unified media | [Driver](screenshots/v0.7.1/unified-media-driver.png) | [Passenger](screenshots/v0.7.1/unified-media-passenger.png) |
| Compact |  | [Passenger, 1024 × 360](screenshots/v0.7.1/compact-passenger.png) |

Additional offscreen QtTest captures show the [live display inventory](screenshots/v0.7.1/display-inventory.png),
[filtered destination](screenshots/v0.7.1/destination-filter.png), and
[explicit recovery](screenshots/v0.7.1/display-recovery.png).

## Frame timing

Each row is one approximately eight-second sample of both WSLg windows
continuously animating Unified media. The same harness, machine, Wayland
platform, render scale and Debian-local state storage were used for both
versions. FPS is derived from Qt `frameSwapped` events. The test measures
swap intervals, with no direct physical-panel timing or frame-lock measurement.

| Version | Logical window | Qt renderer | Driver / passenger FPS | Driver / passenger p95 interval | Driver / passenger intervals over 20 ms |
| --- | --- | --- | --- | --- | --- |
| v0.7.0 | 1280 × 480 | Software | 55.80 / 55.80 | 20.20 / 20.18 ms | 32 / 28 |
| v0.7.1 | 1280 × 480 | Software | 56.76 / 56.76 | 19.09 / 19.12 ms | 7 / 4 |
| v0.7.0 | 1024 × 360 | Software | 58.02 / 58.03 | 18.34 / 18.30 ms | 0 / 1 |
| v0.7.1 | 1024 × 360 | Software | 59.27 / 59.28 | 17.60 / 17.67 ms | 0 / 0 |
| v0.7.1 checkpoint rerun | 1280 × 480 | Software | 56.54 / 56.55 | 19.92 / 19.57 ms | 16 / 12 |
| v0.7.1 checkpoint rerun | 1024 × 360 | Software | 58.79 / 58.78 | 17.99 / 18.12 ms | 0 / 0 |

Both software samples improved on this run. Sustained 60 FPS remains unmet.
The smaller window's compact layout is a supported layout and used the same
software renderer and display scale as the wide window. These samples are
scene-specific and do not establish a performance guarantee or isolate the cost
of individual QML changes.

### GPU acceleration

The WSL2 guest exposes `/dev/dxg` and the WSL Direct3D libraries. With
`GALLIUM_DRIVER=d3d12`, the Qt logs identify OpenGL 4.1 on Intel Iris Xe
through Microsoft D3D12 and Mesa 25.0.7. Both clients failed to register
before the benchmark startup timeout. This occurred in the v0.7.0 threaded
Wayland probe and the v0.7.1 basic-loop Wayland and XWayland probes. No
GPU frame samples were accepted. Qt Quick software is the verified renderer.

#### Single-client follow-up

The unchanged v0.7.1 driver binary at checkpoint `1f91338` was run alone at
1280 × 480 logical pixels through WSLg Wayland, with a fresh server and state
directory for each case. Startup means the client reported online and a
separate backend query confirmed driver registration. Rendering means the
client produced a complete window capture. FPS below counts Qt swap events
over ten local Navigation/Media changes, including waits between changes.
It is workload-specific and differs from the two-window Unified results.

| Renderer | Requested Qt loop | Startup and rendering | Workload FPS |
| --- | --- | --- | ---: |
| Qt Quick software | Basic | Registered in 0.329 s, rendered, exit 0 | 45.74 |
| Qt Quick software | Threaded | Registered in 0.285 s, rendered, exit 0 | 48.59 |
| Default OpenGL, llvmpipe | Basic | Registered in 0.568 s, rendered, exit 0 | 44.53 |
| Default OpenGL, llvmpipe | Threaded | Registered in 0.328 s, rendered, exit 0 | 46.91 |
| D3D12 OpenGL, Intel Iris Xe | Basic | OpenGL context created, SIGSEGV before registration, no capture | — |
| D3D12 OpenGL, Intel Iris Xe | Threaded | OpenGL context created, SIGSEGV before registration, no capture | — |

Qt confirmed the selected basic and threaded loops in the OpenGL logs. The
software logs identified the software backend without confirming distinct
loop implementations. Default OpenGL used CPU-based llvmpipe, so its results
are software results too.

A separate Qt Quick program with one animated rectangle, a periodic heartbeat
and a frame-swap counter reproduced the crash without MacanOS, sockets or a
display coordinator. Default OpenGL produced 218 swaps in the basic loop and
201 in the threaded loop and exited normally. Both forced D3D12 runs created
an OpenGL 4.1 context, then exited with signal 11 before any heartbeat or
swap summary. The reproduction narrows the issue to the Qt Quick and WSLg
D3D12 graphics path. It does not isolate Qt, Mesa, WSLg or the Windows driver
as the faulty component. The single-client test was enough to reproduce the
failure, so the previously failed two-client GPU cases were not repeated.

Local evidence is in `artifacts/v0.7.1/single-renderer-matrix.log` and
`artifacts/v0.7.1/minimal-qt-renderer.log`. The two probe runners and the
minimal Qt source are under the same ignored directory. The software
launcher in [README.md](../README.md) remains the verified fallback.

#### Debian diagnostic tools

GDB 16.3 (`16.3-1`) reproduced SIGSEGV in both Qt render loops. The
llvmpipe control exited normally with 191 frame swaps. In both D3D12
backtraces, `std::string::_M_assign` was called through Intel's
`libigc.so`, with Intel's `libLLVM-9.so` and `libigd12um64xel.so` on
the same stack. This localizes the failure to a call path through Intel's
WSL graphics compiler and driver. Intel function symbols were unavailable.
The exact defect remains unresolved. Keep the software renderer and
revalidate the minimal probe after any approved graphics-stack change.
Local evidence is under `artifacts/v0.7.1/gdb.JWchTOa4/`; the runner is
`artifacts/v0.7.1/qt-render-probe/run-gdb.sh`.

Cppcheck 2.17.1 (`2.17.1-2`) initially rejected the unbuilt Qt-generated
MOC files in the compile database. A filtered copy retained eight compile
entries across seven authored C++ files in `src/` and `tests/`. Using Qt
rules with warning, performance, and portability checks, the run found
seven pass-by-reference or return-by-reference performance suggestions
and no error, warning, or portability diagnostics. Normal analysis limited
branch coverage. Review the suggestions in context before applying them,
especially for Qt interfaces. Rerun the ignored
`artifacts/v0.7.1/run-cppcheck.sh` after generating the compile database
with `cmake -S . -B build-cppcheck -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`.
The report is `artifacts/v0.7.1/cppcheck-initial.log`.

Reproduce from the Debian shell after building:

```sh
sh scripts/check.sh
evidence=$(mktemp -d)
QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
  python3 scripts/measure-rendering.py --output "$evidence"
```

For the compact sample, add `--width 1024 --height 360`. Raw logs and copied
timestamp evidence are under the local `artifacts/v0.7.1/` directory.
The shell check writes to a fresh ignored `artifacts/check.*` directory each
time. CMake's existing XKB and optional QML link-target notices were nonfatal.
