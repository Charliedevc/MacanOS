# MacanOS v0.7.0 desktop validation

## Baseline and changes

The primary repository retains the original `macanos/v0.6` ref at
`13ff84b46bc4a0f6cf21d8ba6018de947a8d8be0`. The v0.7 branch imports its two
application commits as `f2910f3` and `b939856`, with the source commit IDs
recorded by Git. The existing README was retained during import. The separate
`restored-v0.6` checkout remains at the original commit.

- The FigCraft palette drives the shared QML theme. The simulator keeps its
  driver telemetry, passenger journey panel, role-specific layouts and mode controls.
  Compact layouts tighten spacing and shorten labels while retaining accessible names.
- Visible actions have 48 DIP minimum dimensions. Media artwork and controls are
  grouped around playback data, with a compact layout when space is limited.
- Independent page changes fade in. Coordinated transitions ease around the existing
  server-timed cut. Loading uses a pulsing status dot, and connection states have
  distinct text and color. `MACANOS_REDUCED_MOTION=1` removes decorative fades,
  color animations, pulse and waveform motion. Server input and transition rules
  still apply. Automatic OS preference detection was not implemented.
- Unified metadata stays inside each screen. Map geometry repaints only when its
  data or size changes. Each window animates only the waveform bars that intersect
  its viewport. The C++ server, display coordinator, fixture model and protocol
  remain at the verified v0.6 baseline.

## Tests and captures

Debian 13.5 on WSL2, GCC 14.2.0, Qt 6.8.2, CMake 3.31.6, Ninja 1.12.1,
Python 3.13.5, and a Ninja `RelWithDebInfo` build.

| Automated coverage | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| Original coordinator | 12 | 0 | 0 |
| Original QML layouts | 6 | 0 | 0 |
| Original real-process cases | 12 | 0 | 0 |
| New compact layout cases at 640 × 360 and 1024 × 360 | 4 | 0 | 0 |
| **Total** | **34** | **0** | **0** |

The process suite took 43.719 seconds. Qt initialization and cleanup are excluded.
The layout tests also check both dimensions of visible touch targets and the
reduced-motion setting at 640 × 360. WSLg traces show that Wayland configured
the role windows and received buffers from each. The final captures used one
backend, switched through all modes, and closed both clients cleanly.

| Scene | Driver | Passenger |
| --- | --- | --- |
| Independent | [Driver](screenshots/v0.7/independent-driver.png) | [Passenger](screenshots/v0.7/independent-passenger.png) |
| Shared | [Driver](screenshots/v0.7/shared-driver.png) | [Passenger](screenshots/v0.7/shared-passenger.png) |
| Unified navigation | [Driver](screenshots/v0.7/unified-driver.png) | [Passenger](screenshots/v0.7/unified-passenger.png) |
| Unified media | [Driver](screenshots/v0.7/unified-media-driver.png) | [Passenger](screenshots/v0.7/unified-media-passenger.png) |
| Compact |  | [Passenger, 1024 × 360](screenshots/v0.7/compact-passenger.png) |

## Desktop frame timing

Each row samples about eight seconds with both windows continuously animating
Unified media under WSLg Wayland. Per-window timestamps are captured by
`QQuickWindow::frameSwapped` and saved at shutdown. The rate is computed over
the interval between the first and last sample. These are Qt swap events,
without direct measurement of physical presentation or two-panel frame lock.

| Logical window size | Renderer and scale | Driver FPS | Passenger FPS | Driver / passenger p95 interval |
| --- | --- | ---: | ---: | ---: |
| 1280 × 480 | Qt Quick software, WSLg 2× | 44.73 | 42.12 | 37.29 / 38.24 ms |
| 1024 × 360 | Qt Quick software, WSLg 2× | 53.72 | 52.22 | 22.98 / 24.70 ms |
| 1280 × 480 | Default Qt RHI, Mesa llvmpipe | 31.26 | 30.85 | 43.22 / 42.90 ms |
| 1280 × 480 | Qt Quick software, `QT_SCALE_FACTOR=0.5` | 57.41 | 57.42 | 20.17 / 20.50 ms |

**Sustained 60 FPS was not achieved.** The lower render scale was the closest,
with 29 driver and 35 passenger intervals over 20 ms. The default RHI used
CPU software OpenGL. Hardware-accelerated rendering was not measured.

The first exploratory run put trace, diagnostic and PNG files on the Windows
mount and observed stale-state fallback during screenshot capture. Its FPS
figures were discarded because the clients were no longer in the measured
scene. The measured runs used Debian-local storage. The final harness checks
both clients remain in Unified media, captures PNGs outside the sample, and
waits for complete files. Logs, per-frame timestamps and timing JSON are in
the local `artifacts/v0.7/` directory.

Reproduce from the Debian shell after building:

```sh
ctest --test-dir build --output-on-failure
python3 tests/test_processes.py --build build \
  --artifacts artifacts/v0.7/processes --screenshots artifacts/v0.7/offscreen

evidence=$(mktemp -d)
QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
  python3 scripts/measure-rendering.py --output "$evidence"
```

Navigation, GPS, telemetry, journey and media remain simulated. OCTAVE and
Android deployment are outside this milestone. No physical-display, CarPlay,
live telemetry or audible-media results were collected.
