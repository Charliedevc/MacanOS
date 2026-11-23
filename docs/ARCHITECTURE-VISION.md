# MacanOS architecture vision

MacanOS is intended to become an offline-first, modular onboard computing platform for a 2017 Porsche Macan. It should run core services locally, show useful information across two displays, and support hardware replacement without requiring a rewrite of the application. This document describes a proposed architecture and compatibility gates.

## Verified baseline

Checkpoint `1f91338` is the v0.7.1 desktop simulator. Debian WSL2 validation passed 35 automated cases and exercised Independent, Shared, and Unified with two Qt windows, simulated services, persistent display preferences, and disconnect recovery. Qt Quick software rendering is the verified fallback. The WSLg D3D12 crash investigation remains the current engineering task. Physical NaviRider control, Porsche OBD access, CarPlay coexistence, Android deployment, and JL Audio DSP control remain unverified. [Validation report](VALIDATION-v0.7.1.md) · [Roadmap](../ROADMAP.md)

## Host and module boundaries

The same service and UI boundaries should support two host options. A dedicated external computer can own local compute and storage if verified connections expose the intended display and input surfaces. Supported Android hardware can host some or all modules if the exact device and software build provide the required permissions, local storage, lifecycle behavior, and access to the needed surfaces. The display brand and screen count alone do not establish those capabilities.

| Module | Proposed responsibility |
| --- | --- |
| Host and hardware adapters | Local storage, power lifecycle, display inventory, touch, vehicle diagnostic transport, and audio interfaces. Keep hardware-specific behavior at these boundaries. |
| Display coordination | Own role assignment, available modes, viewport geometry, and recovery. Preserve local operation when another display disappears. |
| Read-only diagnostics | Collect explicitly supported observations through one adapter. Expose normalized fault records with source, module, timestamp, and freshness. Enforce read-only commands at both the service and transport boundaries. |
| Troubleshooting knowledge | Store versioned, attributed offline references. Match guidance to the vehicle, module, and fault where known. Keep cached observations, inferred explanations, and unknowns clearly labeled. |
| Navigation, media, and local apps | Run independently of the diagnostic transport. Keep offline maps where licensed and available, cached guidance, and local media usable without internet access. Optional online features should fail independently. |
| Audio adapter | Explore documented interfaces for the planned JL Audio DSP amplifier, upgraded speakers, and subwoofer. Start from a verified signal path and preserve factory warnings, prompts, and audio priority. DSP control remains optional and disabled pending verification. |

Use explicit interfaces and capability reporting so a module can be replaced or disabled without changing unrelated services. Keep preferences and diagnostic snapshots on the host by default, and make backup and restoration possible before replacing hardware.

## Display and diagnostic workflows

- **Independent.** Each verified surface can show its own view. A single available surface should still offer the diagnostic list and explanation in one interface.
- **Shared.** One surface can display a fault list and selected fault while the other shows details, supporting observations, and offline troubleshooting guidance. The driver view should remain glanceable, with detailed interaction reserved for a passenger or parked use.
- **Unified.** A coordinated canvas spans two MacanOS-owned surfaces only when distinct viewports, geometry, bezel, and touch routing are verified. Keep essential controls within individual screens. Fall back to Independent if a surface becomes unavailable.

Keep the original fault record visible alongside any explanation. If a code or vehicle module cannot be identified reliably, show the observed data and identify the missing information. Preserve existing CarPlay ownership and factory display functions. Any MacanOS coexistence path needs its own verification.

## Vehicle access and installation gates

1. Record the factory display, audio, camera, controls, and sleep/wake behavior before connecting hardware. Validate the host, touch routing, and removable power and wiring on a bench first.
2. Enable only documented and tested diagnostic reads for the intended adapter and modules. Reject fault clearing, coding, actuation, firmware writes, and arbitrary command passthrough. On loss of connection, mark data stale and keep factory operation independent.
3. Verify each display mode and audio path on the exact installation before enabling it. Document how to remove or bypass the onboard computer and audio changes, restore factory wiring and configuration, and check factory behavior afterward.

Future work depends on hardware evidence and explicit authorization. The scope and next engineering task are maintained in the [roadmap](../ROADMAP.md).
