# Multi-display hardware compatibility report

Research date: 2026-11-05. **No NaviRider unit, Android APK, ARM64 build or physical dual-display installation was tested.** Desktop results apply only to the supplied C++17/Qt 6.8.2 Linux simulator. The repository supplied for this work contains reconstructed v0.5 documentation, not its application source.

## Evidence matrix

| Capability | Evidence category | Result and missing evidence |
|---|---|---|
| Two independent QML processes, one coordinator | Desktop verified | Mode switching, isolated app selection, shared session, kill/restart and backend recovery tested over loopback. |
| Panoramic canvas without one framebuffer | Desktop verified | Separate clipped viewports with logical bezel gap; 1280×480, 1920×720 and 1920×1080 simulator renderings. These are test sizes, not verified panel specifications. |
| Different display sizes / DPI / rotated touch | Desktop verified in simulation | Geometry and affine mapping unit tests. No physical touch controller, EDID, connector hotplug or calibration verified. |
| Physical 12.3-inch dual-screen configuration | User-described candidate | Exact seller SKU, panel dimensions, motherboard, SoC, ABI, Android API, firmware build and refresh rates remain unknown. A marketing picture or “dual screen” description is insufficient. |
| Android sees two accessible displays | Unknown for NaviRider | Need DisplayManager enumeration with IDs, flags, metrics and independent content on each panel. The second panel could use an MCU, private surface or vendor-only app. |
| Third-party APK on each panel | Unknown for NaviRider | Need installation and display-targeted launch evidence for two role clients, followed by kill/recovery and touch-routing tests. |
| Android Presentation | Platform API documented; device unverified | Presentation-compatible displays must be exposed and usable by the app. This does not imply that two head-unit panels are eligible. |
| Secondary activity launch | Platform API documented; device unverified | API 26+ launch display targeting is conditional on system features and launch permissions. Manufacturer policy may prohibit it. |
| Launcher / automatic startup | Platform API documented; device unverified | HOME role is user granted where available; boot, background start and OEM restrictions require testing. No firmware replacement is required in principle, but success is not established. |
| HDMI/USB-C video input, dual external video paths | Unknown | Need pinout and an actual input demonstration. HDMI output is not HDMI input. No external Linux-to-NaviRider video compatibility is assumed. |
| USB touchscreen endpoints and per-display input routing | Unknown | Need USB descriptors, Android input-device/display associations, touch test on each panel and repeat after reboot. |
| Factory PCM / CAN decoder / camera / parking / steering controls | Unknown for exact unit | Need wiring diagrams and a bench/installer demonstration that factory functions remain available. MacanOS adds no factory-control commands. |
| Standard factory audio, MOST or JL Audio DSP integration | Unknown / outside this module | No audible audio was tested in v0.6. The existing bass fault is unresolved and no amplifier remedy is asserted. |
| Clock synchronization across physical panels | Unverified | Shared time scheduling is desktop tested; refresh phase, latency, density, compositor and thermal performance are not. No frame-lock claim. |

No new seller specification has been independently verified. The historical AliExpress short link does not identify a stable, verified hardware revision for this report. Seller-advertised specifications from another SKU must not be carried over as facts.

## Android API findings

[DisplayManager](https://developer.android.com/reference/android/hardware/display/DisplayManager) enumerates logical displays and provides display-change listeners. Enumerate all displays, not just presentation candidates; record IDs, density and flags. A physical panel is not necessarily an app-accessible logical display. Android IDs may change across boot, so roles need a verified stable association rather than hardcoded IDs.

[Presentation](https://developer.android.com/reference/android/app/Presentation) is a dialog on a secondary display, with resources/density derived from that display. It can be cancelled when the display or hosting task disappears; handle dismissal and invalid-display exceptions. Current documentation allows presentation-flagged internal displays starting with Android 16; older versions restrict internal presentation targets. A Presentation shares its hosting application's lifecycle and process, so it is not sufficient by itself for MacanOS frontend crash isolation.

[ActivityOptions.setLaunchDisplayId](https://developer.android.com/reference/android/app/ActivityOptions#setLaunchDisplayId(int)) was added in API 26. It targets permitted displays; the setting is ignored if secondary-display activities are unsupported. Public/owned display rules and launch permissions apply. Check [ActivityManager.isActivityStartAllowedOnDisplay](https://developer.android.com/reference/android/app/ActivityManager#isActivityStartAllowedOnDisplay(android.content.Context,int,android.content.Intent)) where available, and handle denial. Two activities can still share one process; independent failure domains require a tested process arrangement, potentially separate application packages. Separate Qt runtimes in one Android package have not been implemented or validated here.

[RoleManager.ROLE_HOME](https://developer.android.com/reference/android/app/role/RoleManager#ROLE_HOME), available from API 29, supports a user-approved HOME role request where that role is available. A launcher needs appropriate HOME intent handling. This does not grant privileged display access, kiosk/device-owner rights, immunity from background restrictions or control of reverse-camera overlays. Older systems use their default-HOME mechanism. Do not alter vendor firmware, device policy or security protections to force compatibility.

Qt's [Window/screen APIs](https://doc.qt.io/qt-6/qml-qtquick-window.html) describe screen selection, but desktop `QWindow::setScreen()` success is not proof of Android platform-plugin support on this head unit. An Android port needs a matching Qt Android toolchain and an actual test of native window/activity/presentation hosting. No Android SDK, NDK, Qt Android kit, Java compiler or ADB executable is available on this development host; no APK was built.

## Recommended architecture decision

**Buy no head unit on the strength of its “dual-screen” label.** Require a returnable bench sample or seller evidence that two ordinary third-party applications can render independently, receive their own touch input, survive one client stopping and retain factory camera/PCM operation. If only mirroring or a private OEM surface is exposed, all three MacanOS modes cannot be promised on those two panels.

Prefer Android-native deployment only after that test succeeds. Keep one shared backend owner; attach two role clients to it. If an external Linux system is needed, prefer a mature dual-output Linux board and independently documented display/input hardware. Raspberry Pi 5 is a conditional bench candidate, not proof that it can drive NaviRider. A compositor such as Wayland is the more practical starting point for separate frontend processes on two outputs; do not assume two EGLFS processes can concurrently own the same DRM device.

UNIFIED is implemented at the application viewport level, so separate display controllers are acceptable **if** both expose independent render and input paths. Physical continuity still requires measured dimensions, bezel gap, density, color/brightness and latency calibration. SHARED and INDEPENDENT need the same independently addressable display prerequisite; software fallback cannot create a missing output path.

## Exact bench evidence required

1. Seller SKU, motherboard revision, SoC and ABI, real API level and firmware build, panel pixel resolutions/refresh, wiring and recovery documentation.
2. Authorized, read-only Android enumeration: `scripts/probe-android.py --serial DEVICE --output evidence.json`. This tool is prepared but unexecuted; it does not unlock, root, change policy or launch controls. Review raw input/display data before sharing it.
3. Independent role content on each accessible display; HOME selection and reboot behavior; touch on each panel; one client killed without the other stopping; repeated display disconnect/reconnect.
4. Run the three mode transitions, native-density geometry and bezel calibration, sunlight/night tests, and continuous visualization while measuring CPU/GPU, memory and temperature. Verify that the compositor does not mirror or override content.
5. Confirm vendor reverse-camera/parking/factory audio behavior with the manufacturer/installer. Do not attach this simulator to factory control modules. Electrical power and ignition integration need a separate automotive design and shutdown test.

Until these gates pass, the purchase decision remains conditional. The next software milestone is to restore v0.5 source, embed this coordinator there, and test an authorized Android bench device; it is not a vehicle installation milestone.
