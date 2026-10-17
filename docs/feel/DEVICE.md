# DEVICE.md: the phone every number in docs/feel comes from

| | |
|---|---|
| Model | Samsung Galaxy S20 FE (SM-G780G), serial R58R622JH4R |
| OS | Android 13 (SDK 33), build TP1A.220624.014.G780GXXSFEYC1 (One UI) |
| SoC / GPU | Snapdragon 865 (`kona`), Adreno 650, Vulkan available (Impeller uses it) |
| Memory | 5.7 GB RAM |
| Display | 1080 × 2400, 480 dpi (device pixel ratio 3.0), top cutout 88 px |
| Refresh rate | 120 Hz active (Samsung "adaptive", `refresh_rate_mode=2`; 60 Hz and 120 Hz modes). **Frame budget 8.33 ms.** |
| Text size | font scale 1.0 (Android 14+ nonlinear scaling does not apply; Android 13) |

## Fair device state (checked before every measurement run)
- Animation scales at 1.0: `window_animation_scale=1.0`, `transition_animation_scale=1.0`,
  `animator_duration_scale` unset (= 1.0). Not changed by the rig.
- Power saving off (`low_power=0`); adaptive refresh left as the owner set it (120 Hz while touching/animating).
- Battery between 60 % and 90 %, temperature under 35 °C (`dumpsys battery`; 80 %, 25.8 °C at the start).
  `tool/dev/perf.sh` rests 20 s between runs so the phone does not heat up.
- Powered over USB (needed for adb); `svc power stayon usb` keeps the screen on during runs (stay_on_while_plugged_in=2).
- No other foreground app; the app is force-stopped between runs, so every run starts cold.
- Profile builds only for numbers (`flutter drive --profile`, `flutter run --profile`); debug builds only for looks and hot reload.

## Notes
- This is a 2020 flagship: it is fast. A budget met here is not proof for low-end phones, but jank here is
  certain jank everywhere. The emulator numbers in docs/ux/PERFORMANCE.md are not comparable (60 Hz, software
  GPU paths).
- 120 Hz halves the budget compared to the 16.7 ms that flutter_driver's built-in "missed budget" counts
  assume, so `tool/dev/perf_summary.dart` judges frames against 8.33 ms itself.
