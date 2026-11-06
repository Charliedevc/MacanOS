# MacanOS

### A Dual-Display Infotainment Platform for the Porsche Macan

MacanOS is an open-source automotive infotainment development project designed for the **2017 Porsche Macan**. Built around the OCTAVE software platform, MacanOS explores a customizable, dual-display cockpit with synchronized interfaces, vehicle telemetry, navigation, media integration, and configurable screen behavior.

The project targets a dual 12.3-inch NaviRider display configuration, with development and validation performed in a desktop simulation environment before hardware deployment.

**Current development milestone: v0.6, desktop prototype**

## Display Architecture

MacanOS supports three display configurations:

| Mode | Description |
|---|---|
| Independent | Driver and passenger screens operate separately with individual interface states. |
| Shared | Both displays synchronize application state while retaining role-specific layouts. |
| Unified | Both displays form a panoramic interface with bezel compensation and touch-coordinate mapping. |

The v0.6 prototype also implements persistent display preferences, synchronized animations, simulated display connectivity, and disconnection fallback behavior.

## Technology Stack

MacanOS builds upon the OCTAVE ecosystem and uses a combination of:

- **C++17 / Qt 6 / QML:** Application architecture and graphical interfaces.
- **CMake:** Native build configuration.
- **Python 3:** Development tooling and simulator orchestration.
- **Linux:** Primary desktop simulation and validation environment.
- **Android:** Intended deployment environment, pending hardware integration.
- **OBD-II:** Read-only vehicle telemetry architecture.
- **SQLite:** Local trip and application data.
- **OpenStreetMap / OSRM:** Navigation architecture.
- **WebSocket / TCP JSON:** Interprocess communication and synchronization.

Not every upstream capability has been integrated into the standalone v0.6 module.

## Project Development

| Version | Development focus |
|---|---|
| v0.2 | Early dual-display architecture and interface development |
| v0.3 | Application services and synchronization improvements |
| v0.4 | Expanded system integration and validation |
| v0.5 | Display management, recovery, supervision, hardware abstraction, and rollback |
| v0.6 | Independent, Shared, and Unified display modes with desktop validation |

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

**Implemented or documented**

- Three desktop display modes
- Persistent display configuration
- Synchronized interface state and animations
- Unified-screen bezel and touch mapping
- Display disconnection fallback
- Historical recovery and hardware-management architecture

**Integration and validation remaining**

- Restore and integrate the complete OCTAVE application baseline
- Merge the v0.6 display module with the existing application services
- Validate navigation, media, telemetry, and recovery regression behavior
- Build and test the integrated Android application
- Verify dual-display access, touch routing, and performance on NaviRider hardware
- Complete in-vehicle testing

The recovered OCTAVE v0.9.5 source archive is a candidate upstream baseline. Its compatibility with the historical MacanOS v0.5 implementation must be verified before integration.

## Safety and Hardware Compatibility

MacanOS is an experimental infotainment project, not a replacement for factory vehicle control or safety systems.

Vehicle diagnostics are intended to remain read-only. The project does not require modification of braking, steering, powertrain, or other safety-critical vehicle controls.

Third-party access to both NaviRider displays, Android multi-display behavior, and hardware-specific touch routing have not yet been verified.

## Roadmap

The immediate development priority is **integrating v0.6 with the recovered OCTAVE application source**, rather than expanding the standalone prototype.

Subsequent milestones include integrated regression testing, Android deployment, NaviRider compatibility validation, and in-vehicle user-interface refinement.

## Upstream Project and Licensing

MacanOS is based on [OCTAVE by RobDeGeorge](https://github.com/RobDeGeorge/OCTAVE).

The OCTAVE v0.9.5 source is distributed under GPLv3. Any imported upstream source must retain the applicable copyright notices, attribution, and license obligations.

See [LICENSING.md](LICENSING.md) for repository-specific licensing notes. The licensing documentation should be reviewed again when upstream source code is imported.

## Project Disclaimer

MacanOS is an independent development project and is not affiliated with, endorsed by, or supported by Porsche AG or NaviRider.

Porsche and Macan are trademarks of their respective owners.

---

**Repository:** [github.com/Charliedevc/MacanOS](https://github.com/Charliedevc/MacanOS)

**Development status:** Active prototype development, v0.6 desktop milestone.
