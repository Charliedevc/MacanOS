# MacanOS v0.1 validation

Executed on 2026-11-04 in this managed Linux workspace. No physical vehicle or
NaviRider hardware was attached. Screenshots are Qt window captures, not mockups.

## Build environment and provenance

- Checked out and verified upstream commit
  `eddd432426c18bc8d548c44bd3c1f5b0d9682924`, then created `macanos/v0.1`.
- Confirmed GPL-3.0-or-later in README/NOTICE and GPLv3 text in LICENSE; retained
  all upstream notices. The branch is local; no fork or commits were published.
- Debian 13, GCC 14.2.0, Qt 6.8.2, CMake 4.4.4, Ninja 1.13.2, Python 3.12.14.
- CMake/Ninja initially absent; Qt runtime libraries existed but development
  files were absent. System installation failed with insufficient permissions.
  Packages were downloaded/extracted into `/workspace/toolchain` instead.
- Initial sandbox network access could not reach the configured proxy; the
  authorized network execution path successfully cloned GitHub and downloaded
  dependencies. Loopback tests also require a network-enabled execution context.
- Backend configuration: Debug, OCTAVE_DEV_TOOLS=OFF, tests ON. Quick3D and
  WebEngine development integrations were absent; phone decoder/native Android
  Auto dependencies were detected. No adb or working PulseAudio service was
  available. Neither phone integration nor audible playback is claimed tested.

Both full backend/test compilation and the independent MacanOS build succeeded.
An intermediate build collided with a test-method rename after its moc generation;
rerunning the build regenerated moc and completed. The final backend rebuild
includes the corrected freeze-frame request formatting.

## Actual results

| Command / coverage | Result |
| --- | --- |
| `cmake --build build -j4` | Full backend and upstream test targets compiled; final incremental rebuild also succeeded |
| `cmake --build build-macanos -j2` | Client and QtTest executable compiled |
| `ctest --test-dir build-macanos --output-on-failure` | 1/1 registered test passed, 3.94 s on final run |
| `python3 macanos/tests/integration.py` | 1/1 real-process integration test passed, 12.460 s on final run |
| `ctest --test-dir build --output-on-failure -j2` | Initial full run: 53/59 passed, 167.34 s |
| Affected upstream tests after fixes and environment correction | 58/59 registered tests have passed across the full run and targeted retests; `tst_qmlfixtures` remains failed |
| `python3 macanos/scripts/run.py --seconds 15` | Started real backend and both clients; orderly shutdown |
| `python3 macanos/scripts/capture.py` | Produced driver/passenger PNGs; both client processes exited 0 |
| `python3 -m py_compile ...` and `git diff --check` | Passed |

The QtTest executable includes request-allowlist checks, stale-to-live transitions,
rejection of cached startup readings, two concurrent clients, teardown of one
client while another remains connected, media calls, backend reconnect and
resubscription, and refusal of a non-simulated backend. These tests use a mock TCP
server for deterministic faults. A teardown callback bug found during the first
run was fixed and the suite passes after recompilation.

The separate Python integration test launches actual OCTAVE and two actual QML
processes. It checks independently selected pages and layout bounds, fresh RPM
and changing speed, shared SQLite trip ID/store readiness, backend media metadata,
DTC-clearing denial for trusted loopback, closing the driver while the passenger
continues, and passenger reconnection after a backend restart. It is not a mock
backend test. Raw final logs are in [test-results](test-results).

## Upstream failures and resolution

1. `tst_obdsim`: the new allowlist exposed malformed freeze-frame requests from
   `QStringLiteral("02%100...")`, where `%10` consumed the placeholder. Fixed
   formatting to explicitly compose mode, PID and frame bytes. All simulator
   cases now pass, including rejection of code clearing and preservation of DTCs.
2. `tst_dashboardwidgets`: timed out at 120 seconds during the initial concurrent
   run. It passed the targeted retest in 99.98 seconds; its isolated import-report
   case also passed. No dashboard implementation was changed to mask the timeout.
3. `tst_boot`: missing optional QML modules, followed by a strict output check
   contaminated by an unset XDG_RUNTIME_DIR warning. After supplying the modules
   and a valid runtime directory, this test passed in 71.10 seconds. Developer-only
   cases intentionally skip because developer tooling is disabled.
4. `sdk_go` / `template_go`: CMake found `/usr/bin/go`, which is not the Go
   compiler. Supplied workspace-local Go 1.24.4 and configured GO_EXECUTABLE;
   the tests passed in 18.44 and 13.77 seconds. Go is not a MacanOS dependency.
5. **Still failing: `tst_qmlfixtures`.** Its four music-device fixtures require
   Qt Quick 3D. Adding the runtime modules exposed the expected incompatibility
   with `QT_QUICK_BACKEND=software`. RHI without a display failed to create an
   OpenGL context. An Xvfb/Mesa attempt created a context but failed shader/pipeline
   requirements. The optional WebEngine-positive case skips because WebEngine
   is not built. MacanOS uses original 2D QML components and does not load these
   3D scenes. Validate this upstream suite on a suitable graphics environment.

A clean all-59-pass run is **not** claimed. The 58/59 figure aggregates the full
run and subsequent targeted retests, rather than presenting them as one run.

## Screenshots and limits

- [Driver](screenshots/driver.png): simulated speed/RPM, coolant, trip status,
  navigation concept and shared media.
- [Passenger](screenshots/passenger.png): live simulator telemetry and shared
  now-playing metadata. Visual inspection caught and corrected an expanding
  sidebar; the live integration test now asserts layout bounds.

Screenshots were captured at 1440x620 using the Qt software renderer. No claim is
made about actual 12.3-inch screen resolution, Android external-display behavior,
NaviRider APIs, audio hardware, vehicle signal availability, touchscreen routing,
startup under automotive power, or thermal performance. Simulation retains its
upstream Jeep identity and does not purport to model a Macan engine.

Simulator trips are stored by real SQLite but are temporary and removed with the
throwaway backend configuration on exit. Persistent trip browsing, a full widget
editor, authenticated remote pairing UI and navigation remain future work.

## Files

Modified upstream files:

- `README.md`: MacanOS entry point.
- `src/managers/obdmanager.cpp`: read-only transport enforcement and freeze-frame fix.
- `src/service/servicebridge.cpp`: API-level DTC-clearing rejection.
- `tests/cpp/tst_obdsim.cpp`: verifies attempted clearing preserves codes.

New implementation and support files:

- `src/managers/readonlyvehiclepolicy.h`
- `macanos/CMakeLists.txt`, `macanos/.gitignore`, `macanos/README.md`
- `macanos/src/main.cpp`, `backendclient.h`, `backendclient.cpp`
- `macanos/qml/Main.qml`
- `macanos/qml/components/{Panel,ActionButton,StatusIndicator,Metric,Gauge,NavigationPanel,MediaCard}.qml`
- `macanos/scripts/run.py`, `capture.py`
- `macanos/tests/tst_macanos.cpp`, `integration.py`
- `macanos/docs/architecture.md`, `validation.md`
- `macanos/docs/test-results/client-ctest.txt`, `live-integration.txt`
- `macanos/docs/screenshots/driver.png`, `passenger.png`
