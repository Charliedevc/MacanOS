# MacanOS roadmap

| Milestone | Verified status |
| --- | --- |
| v0.6 | Historical branch at `13ff84b46bc4a0f6cf21d8ba6018de947a8d8be0`. The isolated Debian WSL2 baseline passed 30 tests. |
| v0.7.0 | Local checkpoint `f47615d`. All 34 desktop cases passed. |
| v0.7.1 | Refined QML, destination filtering, display inventory, recovery, and connected-client shutdown. See the [validation report](docs/VALIDATION-v0.7.1.md) for the final run and captures. |

## Next task after explicit authorization

Investigate why both Intel Iris Xe D3D12 clients stall before registering on this WSLg setup. Reproduce with one unmodified v0.7.1 client first, then with the two-window harness, capturing Qt renderer identity and launcher diagnostics. Use the checked-in software-rendered launcher as the working path. Reassess after a host graphics or WSLg update. Treat hardware GPU validation and sustained 60 FPS as open until two clients complete a measured run.

OCTAVE integration, Android deployment, and physical display or vehicle work remain deferred.
