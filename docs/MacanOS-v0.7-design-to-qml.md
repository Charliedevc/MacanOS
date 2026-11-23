# MacanOS v0.7 design-to-QML handoff

The [FigCraft source](../MacanOS%20v0.7.figcraft) follows the [v0.5 driver](../MacanOS-Unique-Screenshots/v05-driver.png) and [v0.5 passenger](../MacanOS-Unique-Screenshots/v05-passenger.png) captures. Behavioral references are the v0.6 source ZIP and bundle indexed in the [repository audit](MacanOS-v0.7-integration-plan.md). Paths below refer to the recovered v0.6 checkout unless specified.

| FigCraft design | Existing implementation | Integration work |
| --- | --- | --- |
| Design System | `qml/Action.qml` and inline visual values in `qml/Main.qml` | Introduce a single QML theme for color, spacing and type. Preserve existing activation, focus, enabled and selected behavior. Keep the four illustrated states as presentations of the current control and status model. |
| Independent Mode | `qml/Main.qml`, `qml/RouteCanvas.qml`, role handling and local page selection in `src/displayclient.cpp` | Keep the current driver/passenger entry points. Extract shared presentation only where the role layouts use it twice. Use the route canvas for fixtures and plug in a live map provider after source recovery or reconstruction. Render driver telemetry with source and freshness from the read-only adapter. |
| Shared Mode | `qml/Main.qml` approval display, `src/displaycoordinator.cpp` shared focus, and `src/fixturemodel.cpp` proposals and media | Preserve the existing command path, approval authority and session state. Bind proposal status and cancellation to the service contract and keep the active destination until approval. Use one now-playing state. Gate the driver interaction on a MacanOS-owned surface. |
| Unified Mode | `qml/Panorama.qml`, `qml/RouteCanvas.qml` and coordinator geometry, generation and time | Retain viewport math, clipping and calibrated touch checks. Use a common scene coordinate system for routes and media. Position the media library, transport controls and route information inside their respective local safe areas. Treat the visible waveform as decorative in the prototype until a media source supplies one. |
| Android App Launcher | New passenger QML view using `Action.qml`; OCTAVE 0.9.5 Android manifest and Java bridges provide packaging context | Add a small platform bridge for app availability and launch results. Route to allowed passenger surfaces, handle return and audio focus, and expose useful errors. Use the installed official YouTube and Netflix apps. |
| Settings and Display Management | `src/displayclient.cpp` registration and screen handling, `src/displaycoordinator.cpp` eligibility and persisted preferences, example touch profiles in `config/` | Expose inventory and read-only capability reasons before enabling assignment or calibration controls. Use runtime width, height, scale, bezel and orientation. Treat Android device calibration capability as conditional. |
| Recovery and Error States | `qml/Main.qml` footer and errors, client reconnect state, coordinator fallback and resume latch | Derive loading, disconnected and recovered states from the existing connection and session model. Keep the survivor in Independent after coordinated display loss. Disable unavailable commands and require explicit re-entry once eligible. Map app launch failures to the same status vocabulary. |

## Implementation sequence

1. Apply the FigCraft tokens to existing QML and preserve the current object names, actions and test entry points. Treat the 1280 × 480 wide and 1024 × 360 compact designs as layout samples. Use existing 44 DIP regression checks while implementing and testing the proposed 48 DIP control minimum.
2. Port the role layouts and state views behind the existing display client. Verify content bounds, focus, visible text, route handoff, settings persistence, service restart and one-client survival before replacing fixture data.
3. Bind the integrated media, navigation and telemetry adapters. Add Android display and app-launch capabilities only after bench verification. Verify the exact NaviRider pair's DPI, touch routing, supported app placement, CarPlay ownership and audio focus before making Shared or Unified available on hardware.

## Open decisions

- Confirm both NaviRider SKUs, Android/ABI, whether the units share a host, and which surfaces are available while CarPlay is active.
- Measure the actual viewing distances, logical densities, bezel and touch orientation. Confirm on-device typography and daylight/night readability.
- Verify official app installation, playback and isolation, including protected video support and the return path to MacanOS.
- Resolve v0.5 source recovery and the scope of navigation, trip and audio reconstruction before replacing the current fixtures.

The FigCraft frames are static design states. Application behavior and hardware compatibility remain covered by separate Qt, Android and physical acceptance gates.
