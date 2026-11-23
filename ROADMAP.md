# MacanOS roadmap

| Milestone | Verified status |
| --- | --- |
| v0.6 | Historical branch at `13ff84b46bc4a0f6cf21d8ba6018de947a8d8be0`. The isolated Debian WSL2 baseline passed 30 tests. |
| v0.7.0 | Local checkpoint `f47615d`. All 34 desktop cases passed. |
| v0.7.1 | Refined QML, destination filtering, display inventory, recovery, and connected-client shutdown. See the [validation report](docs/VALIDATION-v0.7.1.md) for the final run and captures. |

## Current engineering task

GDB backtraces from the minimal Qt Quick reproducer now show the same Intel WSL graphics compiler and driver call path with both render loops. The exact defect remains unresolved. Next, record the host Intel driver version and identify an update or rollback candidate for approval. Repeat the minimal probes after any approved graphics change before returning to the two-window harness. Continue to use the verified software renderer. [Diagnostic evidence](docs/VALIDATION-v0.7.1.md#debian-diagnostic-tools)

## Proposed platform work

These workstreams describe the long-term direction. The v0.7.1 checkpoint remains the verified baseline, and this planning update starts no implementation milestone.

| Workstream | Proposed outcome | Evidence required before enabling |
| --- | --- | --- |
| Onboard host | Replaceable external computer or capable Android host with local processing, storage, and recovery | Verify lifecycle, display and touch enumeration, offline storage, and failure behavior on the actual candidate. |
| Display modes | Independent, Shared, and Unified on the NaviRider pair | Verify separate surface ownership, touch routing, and factory coexistence. Enable each mode only where its requirements are met. |
| Porsche diagnostics | Read-only fault and telemetry access, with offline troubleshooting guidance across both displays | Verify supported diagnostic reads, data provenance, write rejection, and safe loss-of-connection behavior. Validate the vehicle connection after isolated bench testing. |
| Local services | Navigation, media, and replaceable local apps | Validate usable offline behavior and preserve existing display and factory audio behavior through service failures. |
| Audio | Explore integration with the planned JL Audio DSP amplifier, speakers, and subwoofer | Verify the exact signal path, documented interfaces, and factory warning and prompt audio. Prove an independent rollback before enabling any supported control. |
| Installation | Reversible mounting, power and wiring, with a documented factory restoration path | Record factory behavior before installation and demonstrate recovery, removal, sleep/wake operation, and factory behavior afterward. |

OCTAVE integration, Android deployment, and physical display or vehicle work remain deferred. See the [architecture vision](docs/ARCHITECTURE-VISION.md) for module boundaries and compatibility gates.
