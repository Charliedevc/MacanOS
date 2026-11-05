# Linux deployment engineering

The preferred target is a removable **ARM64 Debian 13/Trixie bench** on Raspberry
Pi 5 with a Wayland compositor and independently wired HDMI/USB-touch monitors.
No target hardware was attached. The source kit includes a native build script,
an experimental pinned Debian multiarch cross-build recipe, user-service template,
configuration examples and tested staging/rollback tools.

**Artifact distinction:** the host AMD64 application package is built and smoke
tested. The ARM64 deliverable is a **source/deployment kit**, without ARM64
executables. A direct ARM container could not execute (`exec format error`); the
cross-build dependency installation encountered repository failures and an OOM
kill. A bounded retry was cancelled before its planned 2 GiB install exhausted
remaining workspace storage. No full ARM64 Qt build/run is claimed. Run the native
build on a board or a provisioned ARM64 builder before purchasing installation
hardware. The recipe is not described as a certified cross-toolchain.

## Native ARM64 build

Install the packages listed in `debian-packages.txt` using the target's normal
package manager. Stock Debian 12's Qt 6.4 is below the application's Qt 6.7 minimum;
use Debian 13/Qt 6.8 or an explicitly provisioned matching Qt kit. Use a GPU/Wayland
stack supported by the actual board image. The native script makes no package,
bootloader, firmware, vehicle or system-service changes:

```sh
# From a source-kit checkout on an ARM64 target:
sh macanos/deploy/linux/build-native.sh /path/to/build-arm64
# Creates /path/to/build-arm64/macanos-arm64.tar.gz plus SHA-256 file.
```

It refuses an x86 host instead of relabeling x86 binaries as ARM64. The packager
checks ELF64 `e_machine` on **both** backend and frontend. The backend uses
`OCTAVE_DEV_TOOLS=OFF`, `OCTAVE_BUILD_TESTS=OFF`; frontend uses `BUILD_TESTING=OFF`.
C++17, Qt and TagLib are required; bundled SQLite is reused. Build concurrency is
two. Reduce it on memory-limited boards and provide enough temporary disk/swap.

The cross-build alternative is prepared for a larger AMD64 builder:

```sh
# CA bundle is mounted, not copied into the resulting image.
docker build --secret id=system_ca,src=/etc/ssl/certs/ca-certificates.crt \
  -f macanos/deploy/linux/Dockerfile.arm64 -t macanos-arm64-build:v05 .
```

The recipe pins the Debian base digest and repository snapshot, uses native Qt
host tools plus target ARM64 Qt and an AArch64 compiler, preserves certificate
verification, caches downloads and bounds installer memory. Provision at least
several GiB of free storage beyond the dependency plan and adequate RAM. Build
logs show the actual failures in this environment; no target binaries were exported.
If it completes elsewhere, copy `/build/backend/octave` and
`/build/client/macanos-client` from a created container, verify with `file/readelf`,
and package them with `package_linux.py --arch arm64`. QEMU execution is a separate
validation step, not supplied by the current container recipe.

## Packages, staging and rollback

The thin application package includes `bin/octave`, `bin/macanos-client`, runtime
scripts, configuration, deployment templates, root LICENSE/NOTICE, a manifest and
SHA-256 file. Qt/QML/plugins, TagLib, codec/system libraries and the compositor are
**OS dependencies**, not bundled from the development kit. The default package
includes a corresponding-source archive. `--skip-source` is for local test artifacts
only. Keep source/notices and review Qt/codec/library terms before redistribution.
There is no filesystem image, OS updater or factory firmware modification.

```sh
# Example on the development host; --arch must match the actual ELF files:
python3 macanos/scripts/package_linux.py --backend build/octave \
  --client build-macanos/macanos-client --arch amd64 \
  --output macanos/artifacts/macanos-v0.5-amd64.tar.gz

# Example commissioning commands on a reviewed target/user account:
python3 macanos/scripts/release.py --root ~/.local/opt/macanos \
  stage /path/to/macanos-arm64.tar.gz v0.5
python3 macanos/scripts/release.py --root ~/.local/opt/macanos check v0.5
# Stop supervision before switching. --runtime must match kiosk.json.
python3 macanos/scripts/release.py --root ~/.local/opt/macanos \
  activate v0.5 --runtime ~/.local/state/macanos/runtime
# Later, while stopped:
python3 macanos/scripts/release.py --root ~/.local/opt/macanos \
  rollback --runtime ~/.local/state/macanos/runtime
```

The tool validates checksums, rejects archive traversal/symlink members and invalid
release IDs, refuses a mismatched architecture on activation and changes `current`
atomically. It keeps the previous release ID for explicit rollback. It takes the
supervisor's lock, so using the same runtime path prevents switching a running
session. Checksums are integrity checks, not publisher authentication. No activation,
user-service installation or system changes were made outside the workspace.

Back up profile data before an update or schema change:

```sh
python3 macanos/scripts/backup_profile.py /path/to/profile /path/to/new-backup-dir
```

SQLite uses its consistent backup API; preference files are copied separately.
Music/logs are excluded. Prefer stopping supervision for a whole-profile checkpoint.
Code rollback does **not** reverse database migrations. v0.5 adds no trip schema
migration; a future downgrade needs a compatible backup and explicit review.
Never erase a profile to fix a failed launch.

## Startup and independent supervision

The original desktop launcher remains available:

```sh
python3 macanos/scripts/run.py
```

The new kiosk supervisor keeps each process running, even after normal window
closure. Ctrl+C/SIGTERM or a simulated power-off stops it:

```sh
python3 macanos/scripts/supervise.py --config macanos/config/desktop-kiosk.json --check
python3 macanos/scripts/supervise.py --config macanos/config/desktop-kiosk.json
```

Configuration paths resolve relative to the configuration file. `schema: 1` and
`mode: simulator` are enforced; no physical vehicle mode is enabled. The supervisor
refuses an occupied backend port, starts one OCTAVE `--headless --sim` backend,
verifies protocol/simulation, and creates two clients. Each child is restarted
independently with bounded exponential delay; nine short-life failures stop the
session instead of endlessly thrashing. A backend restart retains client processes
and the persistent profile. Startup readiness timing is logged separately from
hardware boot time.

`runtime/events.jsonl` and stdout contain timestamped JSON events and tagged child
output; `supervisor.json` contains current PIDs/status. Per-role JSON state reports
connection, telemetry, trips, navigation, display presence and its PID. `started`,
`backend_ready`, `frontend_ready`, `exited`, `forced_stop` and `stopped` distinguish
normal recovery from forced termination. Logs can grow: configure retention through
journald or external rotation for an endurance test; rotation is not implemented
inside the supervisor. Do not make claims about long-term storage use from a short
benchmark.

`macanos.service` is an opt-in **systemd user service** template for a graphical
session. Review/copy it to `~/.config/systemd/user/`, and copy/edit `kiosk.json` under
`~/.config/macanos/`. It expects code under `~/.local/opt/macanos/current`. Normal
Qt platform/runtime libraries must be installed. A Wayland session may need its
`WAYLAND_DISPLAY`/runtime environment imported into the user manager. This workspace
has no usable graphical systemd user session; service enable/boot integration was
not executed. Manual supervisor startup was tested.

The client handles SIGTERM on its Qt thread, allowing QSettings/render metrics to
flush. Shutdown requests both clients and the backend, allows ten seconds per
process, then logs any forced kill. Backend normal shutdown closes SQLite trips;
crash recovery is separately tested. A corrupt/missing power file is treated as
unknown and does not power down the host.

## Display and touch commissioning

```sh
./build-macanos/macanos-client --list-screens
python3 macanos/scripts/hardware_probe.py --client build-macanos/macanos-client \
  --output /tmp/macanos-hardware.json
./build-macanos/macanos-client --role driver --screen HDMI-A-1 --fullscreen \
  --width 1920 --height 720 --map-theme night
```

Use actual Qt names or `serial:MEASURED_SERIAL` values, not example connector names.
EDID serials may be blank/duplicated; ambiguous selectors wait with the window
hidden. Fullscreen kiosk roles require distinct explicit selectors. On removal,
the matching client hides rather than falling back over the other screen; on
return it shows again. This was tested with an explicitly simulated display
inventory; no physical cable event was measured. The CLI width/height are logical
window dimensions, not commands to set a panel timing mode.

Use a compositor that can place two independently supervised clients, with output
rules for app IDs `org.macanos.driver` / `org.macanos.passenger` or their window
titles. Validate actual QScreen/compositor behavior on target. Two raw EGLFS/KMS
processes are not an assumed substitute for a multi-client compositor.

`touch-example.json` contains **simulated USB IDs**, normalized affine transforms
and output labels. Validate and render a reviewable preview:

```sh
python3 macanos/scripts/touch_profiles.py macanos/config/touch-example.json \
  --output /tmp/touch-preview.json
```

The tool does not install rules, change input devices or apply transformations to
Qt's event stream. It generates libinput calibration properties; output association
still belongs to the selected compositor. Replace USB IDs/output labels from
measured hardware; identical controllers need stable serial/path matching, which
this simple VID/PID template deliberately rejects. C++/QML tests exercise rotated
calibration math and a synthetic touch activating a real media button. This is
software input validation, not a USB touchscreen compatibility test.

## Offline and power boundaries

`offline: true` sets `MACANOS_OFFLINE=1`: navigation rejects online map activation,
online search is reduced to saved/coordinate results, new routing requests are
disabled, and automatic update checks are suppressed. Licensed offline XYZ packs
and the existing matching route cache can still work; no regional data is bundled.
Supply offline attribution separately. Offline boot does not promise a route where
none was cached or a map pack where no coverage was licensed. Unrelated vendor
firmware, other apps and future plugins are outside this application's offline
switch.

For bench power simulation, set `power_event_file` to a file containing:

```json
{"source":"simulated","ignition":"on"}
```

Changing `ignition` to `off` asks the supervisor to stop MacanOS gracefully. Other
sources/invalid JSON/unknown values do not request shutdown. This never runs
`shutdown`, toggles GPIO, cuts electrical power, sends CAN or controls the car.
A real isolated ignition input, protected supply, hold-up circuit and post-halt
power removal are still missing hardware integrations.
