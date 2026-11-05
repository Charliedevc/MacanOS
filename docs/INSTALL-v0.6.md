# Installation and operation

Follow the root README build commands. This package includes source and test evidence, not portable prebuilt binaries. Qt development and runtime components must come from compatible installations. Qt 6.7+ is required. Debian 13/Qt 6.8.2 was used here; older distributions may need a separately installed Qt kit and `CMAKE_PREFIX_PATH`.

## Three processes

The convenience launcher uses one server and two separately spawned client executables. For manual launch, run these in separate terminals from the repository root:

```sh
./build/macanos-display-server --port 45670 --settings .runtime/modes.json
./build/macanos-display-client --role driver --port 45670 --settings .runtime/driver.ini
./build/macanos-display-client --role passenger --port 45670 --settings .runtime/passenger.ini
```

The server listens only on IPv4 loopback. There is no remote/LAN transport in this module. No OBD, GNSS, CAN, factory audio or vehicle control device is opened. Do not start this as a replacement for an installed v0.5 backend; it is an isolated simulator.

For configured 1920×720 simulator windows:

```sh
python3 scripts/run-simulator.py --width 1920 --height 720
```

For two physical Qt outputs, after confirming their Qt screen indices:

```sh
python3 scripts/run-simulator.py --driver-screen 0 --passenger-screen 1 --fullscreen
```

Physical output use is prepared, not verified. The current simulator validates 1280×480, 1920×720 and 1920×1080 logical windows. Other aspect ratios and smaller windows may need further layout work. Qt's compositor determines actual window size and output density; a fullscreen resize re-registers the resulting dimensions. Avoid assuming the candidate NaviRider exposes two Qt screens.

A client accepts `--width`, `--height` in native pixels and `--scale` in pixels/DIP. For a 1920×720 configured surface at scale 1.5, the logical viewport is 1280×480. `--touch-profile config/touch-rotate-180.json` loads an affine profile. Match the scale to the verified output configuration. Profiles do not reroute OS input devices or calibrate physical hardware.

## Runtime controls

Both windows have mode and Navigation/Media buttons. Mode changes are scheduled on the shared server clock. Buttons are disabled during incompatible transitions; INDEPENDENT can always interrupt while connected. The read-only server boundary is unchanged by mode selection.

The launcher also exposes optional command files:

```sh
python3 scripts/control.py setMode UNIFIED
python3 scripts/control.py localApp media
python3 scripts/control.py setUnifiedScene navigation
python3 scripts/control.py setBezelGap 30
python3 scripts/control.py --role driver screenshot /tmp/macanos-driver.png
```

A bezel change in active UNIFIED falls back to INDEPENDENT until explicitly resumed. A logical gap is not a millimetre calibration. Desktop UNIFIED has local headers over the shared scene; it intentionally avoids placing essential controls inside the bezel.

To simulate loss of the passenger output while retaining its process:

```sh
python3 -c 'import json,pathlib; pathlib.Path(".runtime/presence.json").write_text(json.dumps({"driver": True, "passenger": False}))'
```

Set `passenger` back to `true` or remove that file to restore it. Select the saved mode explicitly after recovery. Closing one frontend or killing its process exercises a separate failure path. The backend process does not restart during either operation.

## Persistence and recovery

- `modes.json`: schema 1, requested mode, shared app, unified scene and logical bezel gap; written with QSaveFile atomic replacement. Invalid settings start with INDEPENDENT defaults and an error indication.
- `driver.ini` / `passenger.ini`: independent Navigation/Media selections. These are separate local states, even while a coordinated mode is active.
- Diagnostic JSON includes mode, availability, PID, clock uncertainty, last command result and latest backend snapshot. It is simulator instrumentation, not production vehicle logging.
- Fixture route/media/telemetry state resets with the simulator backend. This does not implement or test v0.5 trip/media persistence.

If the backend restarts, clients reconnect and register on its new session UUID. The saved mode becomes active after both register. If one display disappeared during a running coordinated session, returning does not automatically resume it. A live geometry change also requires explicit resume.

No global installation or system service is installed by these scripts. To roll back this local module, stop its processes and check out `cefde60`; keep `.runtime` separately if settings are needed. That rollback returns to documentation only, not the absent working v0.5 application.
