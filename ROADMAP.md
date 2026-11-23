# MacanOS roadmap

| Milestone | Verified status |
| --- | --- |
| v0.6 | Historical branch at `13ff84b46bc4a0f6cf21d8ba6018de947a8d8be0`. The isolated Debian WSL2 baseline passed 30 tests. |
| v0.7.0 | Local checkpoint `f47615d`. All 34 desktop cases passed. |
| v0.7.1 | Refined QML, destination filtering, display inventory, recovery, and connected-client shutdown. See the [validation report](docs/VALIDATION-v0.7.1.md) for the final run and captures. |

## Next task after explicit authorization

The D3D12 failure reproduces in one unchanged v0.7.1 client and in a minimal Qt Quick window. Next, collect a symbolized crash backtrace from the minimal program before changing the host graphics stack. Compare the basic and threaded paths. Retest the minimal probe after any approved graphics update before returning to the two-window harness. Continue to use the software renderer for the simulator.

OCTAVE integration, Android deployment, and physical display or vehicle work remain deferred.
