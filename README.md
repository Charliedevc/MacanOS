# MacanOS

### A Modular Onboard Computing Platform for the 2017 Porsche Macan

MacanOS is an open-source project to build a locally operated onboard computing platform for the **2017 Porsche Macan**. The long-term design pairs onboard processing and storage with independent software modules for display coordination, read-only Porsche diagnostics, navigation, media, and local apps.

The proposed installation targets two 12.3-inch NaviRider displays and can use a dedicated external computer or supported Android hardware, subject to verification. The platform should work offline for its core functions and be removable without compromising factory functionality. The planned JL Audio DSP amplifier, speakers, and subwoofer are potential integration points. See the [architecture vision](docs/ARCHITECTURE-VISION.md).

**Verified baseline:** v0.7.1 desktop simulator, checkpoint `1f91338`. It exercises synchronized interfaces and configurable screen behavior with simulated telemetry, navigation, and media. The 35 automated cases and three display modes were verified in Debian WSL2.

## Build and launch

From Debian WSL2 in this checkout, with Qt 6.7+, a C++17 compiler, CMake 3.21+, Ninja and Python 3 installed:

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build --parallel 4
QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
  python3 scripts/run-simulator.py --state-dir "$HOME/.local/state/macanos-v07"
```

The launcher opens one driver window and one passenger window. The **Displays** button opens the simulator display inventory. Passengers can filter the built-in destination list and propose a route for the driver to approve. Press Ctrl+C in the terminal to stop both windows. Set `MACANOS_REDUCED_MOTION=1` before launch to use static connection cues and omit decorative motion. The [v0.7.1 validation report](docs/VALIDATION-v0.7.1.md) records test results, screenshots, and measured frame timing.

## Display Architecture

The desktop simulator supports three display configurations:

| Mode | Description |
|---|---|
| Independent | Driver and passenger screens operate separately with individual interface states. |
| Shared | Both displays synchronize application state while retaining role-specific layouts. |
| Unified | Both displays form a panoramic interface with bezel compensation and touch-coordinate mapping. |

The simulator also implements persistent display preferences, synchronized animations, simulated display connectivity, and disconnection fallback. Operation on the physical NaviRider pair remains a proposed capability.

## Technology Stack

The desktop simulator uses:

- **C++17 / Qt 6 / QML:** Application architecture and graphical interfaces.
- **CMake:** Native build configuration.
- **Python 3:** Development tooling and simulator orchestration.
- **Linux:** Primary desktop simulation and validation environment.
- **Loopback TCP JSON:** Interprocess communication and synchronization.

Earlier engineering records describe OCTAVE services, Android deployment, read-only OBD-II, SQLite trip storage, and OpenStreetMap / OSRM routing. Those integrations remain outside this desktop build.

## Project Development

| Version | Development focus |
|---|---|
| v0.2 | Early dual-display architecture and interface development |
| v0.3 | Application services and synchronization improvements |
| v0.4 | Expanded system integration and validation |
| v0.5 | Display management, recovery, supervision, hardware abstraction, and rollback |
| v0.6 | Independent, Shared, and Unified display modes with desktop validation |
| v0.7.0 | Responsive layouts, 48 DIP controls, and coordinated desktop animations |
| v0.7.1 | Route and media refinement, destination filtering, display inventory, and recovery controls |

Historical development records are preserved in [`v0.2.md`](v0.2.md), [`v0.3.md`](v0.3.md), [`v0.4.md`](v0.4.md), and [`v0.5.md`](v0.5.md).

## v0.6 Deliverables

The repository includes the [v0.6 deliverables](MacanOS-v0.6-Deliverables), containing:

- Source code archive and Git bundle
- Engineering and validation reports
- Desktop simulation screenshots
- Delivery manifest and SHA-256 checksums
- Setup and execution instructions

The v0.6 development record reports **30 passing automated tests and 10 captured Qt screenshots**. These results apply to the standalone desktop module, not a fully integrated vehicle installation.

See the [v0.6 engineering report](MacanOS-v0.6-Deliverables/MacanOS-v0.6-Report.md) for implementation details and validation limitations.

## Screenshots

Historical interface screenshots are available in the [MacanOS screenshot gallery](MacanOS-Unique-Screenshots).

These images document the visual evolution of the driver and passenger interfaces. They should not be interpreted as evidence of successful deployment to physical NaviRider hardware.

## Current Development Status

The v0.7.1 checkpoint verifies the desktop simulator only. Proposed platform capabilities include detailed Porsche fault information, a companion troubleshooting view on the second screen, and offline access to locally stored guidance. Vehicle diagnostics, physical display control, CarPlay coexistence, Android deployment, and DSP control all require separate validation.

## Safety and Hardware Compatibility

Preserve factory controls, safety systems, and normal vehicle operation throughout testing and installation. Require read-only vehicle diagnostics, with no fault clearing, coding, actuation, or firmware writes. Any installation must have a documented way to restore the original configuration.

## Roadmap

The [roadmap](ROADMAP.md) keeps the current WSLg D3D12 diagnostic separate from future platform work. Qt Quick software remains the verified desktop fallback.

## Upstream Project and Licensing

MacanOS is based on [OCTAVE by RobDeGeorge](https://github.com/RobDeGeorge/OCTAVE).

The OCTAVE v0.9.5 source is distributed under GPLv3. Any imported upstream source must retain the applicable copyright notices, attribution, and license obligations.

See [LICENSING.md](LICENSING.md) for repository-specific licensing notes. The licensing documentation should be reviewed again when upstream source code is imported.

## Project Disclaimer

MacanOS is an independent development project and is not affiliated with, endorsed by, or supported by Porsche AG or NaviRider.

Porsche and Macan are trademarks of their respective owners.

---

**Repository:** [github.com/Charliedevc/MacanOS](https://github.com/Charliedevc/MacanOS)

**Development status:** Active prototype development, v0.7.1 desktop milestone.
