# MacanOS

### A Dual-Display Infotainment Platform for the Porsche Macan

MacanOS is an open-source automotive infotainment development project designed for the **2017 Porsche Macan**. The project explores a customizable, dual-display cockpit with synchronized interfaces, navigation, media, vehicle telemetry, and intelligent display management.

Developed primarily with **C++17, Qt 6, and QML**, MacanOS combines native application performance with a modular interface designed for independent and coordinated display operation.

The target hardware configuration consists of two separate **12.3-inch NaviRider touchscreen displays**, with Apple CarPlay intended for the driver and Android applications for the passenger, subject to hardware compatibility.

Development, testing, and performance evaluation currently take place in a Linux desktop simulation environment using Debian WSL2.

**Current development milestone: v0.7.0, dual-display desktop prototype**

> MacanOS is under active development. Desktop simulation is functional, but physical vehicle and NaviRider integration have not been validated.

---

## Display Architecture

MacanOS supports three configurable display modes:

| Mode | Description |
|---|---|
| **Independent** | Driver and passenger displays operate independently with role-specific interfaces and navigation states. |
| **Shared** | Both displays synchronize application state, including destination proposals and simulated media controls, while maintaining their individual layouts. |
| **Unified** | Both displays operate as coordinated viewports of a panoramic interface with bezel compensation and touch-coordinate transformations. |

The display architecture includes:

- Persistent display preferences and settings.
- Driver and passenger role management.
- Shared application state synchronization.
- Coordinated display-mode transitions.
- Display registration and heartbeat monitoring.
- Disconnection detection and automatic fallback.
- Display reconnection and explicit session resumption.
- Configurable viewport geometry and touch transformations.

These capabilities have been implemented and validated within the desktop simulator.

## Technology Stack

MacanOS uses a native application architecture with supporting development and integration technologies.

| Technology | Responsibility |
|---|---|
| **C++17** | Application backend, display coordination, state management, and interprocess communication |
| **Qt 6 / QML** | Driver and passenger graphical interfaces, animations, and responsive layouts |
| **CMake / Ninja** | Native application configuration and compilation |
| **Python 3** | Desktop simulator orchestration, testing, automation, and performance measurement |
| **Debian Linux / WSL2** | Primary development and desktop validation environment |
| **TCP / JSON** | Communication between the backend server and display clients |
| **QtTest** | Automated C++ testing and interface validation |
| **FigCraft** | Visual design system, component specifications, and interface prototyping |

### Planned integrations

Additional technologies under evaluation include:

- **OCTAVE:** Reusable media, telemetry, Android, and application services.
- **OpenStreetMap / OSRM:** Map rendering and navigation routing.
- **OBD-II:** Read-only vehicle telemetry and diagnostics.
- **SQLite:** Persistent trip and application data.
- **Android:** Potential deployment platform for compatible infotainment hardware.

These planned technologies should not be interpreted as fully integrated or validated features of the current v0.7.0 application.

## Project Development

| Version | Development focus |
|---|---|
| v0.2 | Early dual-display architecture and interface development |
| v0.3 | Application services, navigation concepts, and synchronization |
| v0.4 | Expanded routing, audio adapters, and system validation |
| v0.5 | Supervision, display recovery, hardware abstraction, and rollback architecture |
| v0.6 | Functional Independent, Shared, and Unified desktop display simulation |
| **v0.7.0** | **Restored application baseline, refined Qt/QML interfaces, responsive layouts, animations, and performance validation** |
| v0.7.1 | Planned further visual refinement and performance optimization |
| v0.8 | Planned functional navigation and media integration |
| v0.9 | Planned Android and hardware compatibility development |

Historical engineering documentation is preserved in [v0.2.md](v0.2.md), [v0.3.md](v0.3.md), [v0.4.md](v0.4.md), and [v0.5.md](v0.5.md).

The original v0.5 application source has not been recovered. Its documented features must be distinguished from the currently available application code.

---

## MacanOS v0.7.0

Version 0.7.0 builds upon the verified v0.6 application and introduces refinements to the graphical interface while preserving the existing C++ display architecture.

### Interface improvements

- Refined dark visual theme based on the MacanOS FigCraft design system.
- Improved driver and passenger layout responsiveness.
- Consistent typography, spacing, and interactive components.
- Touch-friendly controls using 48 DIP design targets.
- Smooth page transitions and coordinated mode changes.
- Improved media and navigation panel presentation.
- Loading, stale-connection, and recovery-state feedback.
- Reduced-motion support through an environment setting.
- Improved handling of compact display sizes.

The application preserves its existing backend-driven synchronization and display recovery mechanisms.

### Design system

MacanOS uses a custom visual design system defined in FigCraft.

| Design token | Color |
|---|---|
| Background | `#0B0E12` |
| Panel | `#151A21` |
| Border | `#29313B` |
| Accent | `#E46270` |

The [v0.7 design-to-QML documentation](docs/MacanOS-v0.7-design-to-qml.md) describes the relationship between the design system and the application components.

The FigCraft project contains seven design pages covering display modes, application launching, settings, and recovery states. Not all conceptual designs are implemented in the runtime.

## Validation and Testing

MacanOS v0.7.0 has been compiled and tested on Debian 13.5 under WSL2.

**Latest reported results: 34 passed, 0 failed, 0 skipped.**

| Test category | Passed |
|---|---:|
| Display coordinator | 12 |
| Layout validation | 6 |
| Real-process integration | 12 |
| Additional compact-layout tests | 4 |
| **Total** | **34** |

Desktop validation confirmed:

- Successful compilation of the backend and display clients.
- Driver and passenger windows launching through WSLg.
- Independent, Shared, and Unified operation.
- Shared backend connectivity.
- Role-specific and responsive layouts.
- Display state synchronization.
- Settings persistence.
- Display disconnection and recovery.
- Clean process shutdown.

The tests validate the desktop application, not physical vehicle operation.

### Performance

Rendering performance was measured with both display windows active in Unified media mode.

| Configuration | Average FPS |
|---|---:|
| Driver, software rendering | 44.73 |
| Passenger, software rendering | 42.12 |
| Reduced render scale | Approximately 57.4 per window |

These results were obtained under WSLg using Qt Quick software rendering. Sustained 60 FPS was not achieved at the default render scale.

GPU-accelerated performance on target hardware remains unverified.

For technical details, see [v0.7 desktop validation](docs/VALIDATION-v0.7.md).

---

## Running the Desktop Simulator

### Requirements

The validated environment uses:

- Debian 13.5 under WSL2.
- GCC 14.2.0.
- Qt 6.8.2.
- CMake 3.31.6.
- Ninja 1.12.1.
- Python 3.13.5.
- WSLg for graphical display output.

### Build

From the MacanOS repository in Debian, with the required development packages installed:

```bash
cmake -S . -B build -G Ninja
cmake --build build --parallel
```

### Launch

```bash
QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software \
python3 scripts/run-simulator.py
```

Alternatively, launch directly from Windows PowerShell:

```powershell
wsl.exe -d Debian --cd /mnt/c/Users/Owner/Documents/MacanOS --exec env QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software python3 scripts/run-simulator.py
```

The simulator launches a shared backend and two graphical clients representing the driver and passenger displays.

Use the interface controls to switch display modes. Press `Ctrl+C` in the terminal to terminate the simulator.

### Reduced-motion mode

```bash
MACANOS_REDUCED_MOTION=1 \
QT_QPA_PLATFORM=wayland \
QT_QUICK_BACKEND=software \
python3 scripts/run-simulator.py
```

This disables decorative interface motion. Automatic detection of operating-system reduced-motion preferences is not yet implemented.

## Screenshots

Historical interface screenshots are available in the [MacanOS screenshot gallery](MacanOS-Unique-Screenshots).

Updated v0.7.0 simulator screenshots are available in [docs/screenshots/v0.7](docs/screenshots/v0.7).

The latest screenshots document the desktop implementation of the driver and passenger interfaces across supported display modes.

All current navigation, speed, RPM, and media examples shown in these screenshots are simulator data.

---

## Current Development Status

### Implemented and desktop-validated

- Native C++/Qt backend and display clients.
- Dual-window desktop simulation.
- Independent, Shared, and Unified display modes.
- Persistent display settings.
- Synchronized interface state.
- Panoramic viewport and bezel handling.
- Touch-coordinate transformation logic.
- Display connectivity and recovery management.
- Responsive Qt/QML interface.
- Interface transitions and connection-state feedback.
- Automated regression testing.

### Simulated or incomplete

- GPS positioning and route guidance.
- Vehicle speed and RPM.
- Journey distance and ETA.
- Media playback state and audio controls.
- Destination proposal workflows operating on fixture data.
- Persistent trip recording and historical navigation services.

### Not yet validated

- Physical NaviRider touchscreen compatibility.
- Apple CarPlay coexistence and display ownership.
- Android application deployment.
- YouTube and Netflix application launching.
- Protected media playback and audio routing.
- Live OBD-II communication.
- Vehicle-specific performance and touch calibration.
- In-vehicle operation.

## Development Roadmap

The next phase focuses on strengthening the existing desktop application before expanding hardware integration.

**v0.7.1: Interface refinement**

- Bring remaining Qt/QML layouts closer to the FigCraft specifications.
- Improve animations and interaction feedback.
- Optimize rendering and frame pacing.
- Evaluate hardware-accelerated Qt rendering.
- Maintain existing regression coverage.

**v0.8: Functional application services**

- Integrate real navigation and routing capabilities.
- Introduce functional media playback.
- Evaluate selected OCTAVE components.
- Extend application state and trip management.
- Validate integrations through desktop testing.

**v0.9: Android and hardware preparation**

- Investigate compatible Android deployment methods.
- Validate NaviRider display capabilities.
- Evaluate independent display ownership and touch routing.
- Verify coexistence with factory infotainment and CarPlay.
- Begin hardware-specific performance testing where feasible.

These milestones are development targets, not guarantees of hardware compatibility.

---

## Upstream Project and Licensing

MacanOS draws on the architecture and ecosystem of [OCTAVE by RobDeGeorge](https://github.com/RobDeGeorge/OCTAVE).

The recovered OCTAVE v0.9.5 source is being evaluated as a potential integration baseline. It has not yet been incorporated into the current v0.7.0 desktop runtime.

OCTAVE is distributed under GPLv3. Any imported upstream source must preserve applicable copyright notices, attribution, and licensing requirements.

See [LICENSING.md](LICENSING.md) for repository-specific licensing information.

## Safety and Hardware Compatibility

MacanOS is an experimental infotainment development project, not a replacement for factory vehicle systems.

Vehicle telemetry is intended to remain read-only. The project does not require modifications to braking, steering, powertrain, or other safety-critical vehicle controls.

Physical display integration, touch routing, Android compatibility, and Apple CarPlay coexistence require additional validation.

No current desktop test result should be interpreted as verification of vehicle compatibility.

## Project Disclaimer

MacanOS is an independent development project and is not affiliated with, endorsed by, or supported by Porsche AG or NaviRider.

Porsche and Macan are trademarks of their respective owners.

---

**Repository:** [github.com/Charliedevc/MacanOS](https://github.com/Charliedevc/MacanOS)

**Development status:** Active prototype development, v0.7.0 desktop milestone. Local implementation validated, GitHub publication pending.
