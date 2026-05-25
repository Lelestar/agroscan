# AgroScan Mobile (Flutter)

Android app for preliminary plant disease screening. **On-device** inference via TensorFlow Lite (offline).

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **stable** (tested with Flutter 3.44) — follow the official guide for your OS
- Android SDK (API 26+; Android Studio or command-line tools)
- A physical device with USB debugging, or an Android emulator

Install Flutter for [Windows](https://docs.flutter.dev/get-started/install/windows), [macOS](https://docs.flutter.dev/get-started/install/macos), or [Linux](https://docs.flutter.dev/get-started/install/linux), then run:

```bash
flutter doctor
```

Fix anything `flutter doctor` flags (Android licenses, SDK paths) before continuing.

### Platform notes

| OS | Tips |
|----|------|
| **Windows** | Use **PowerShell** or **Git Bash** for shell scripts in the repo root. `validate_advice_coverage` can also be run with `dart run tool/validate_advice_coverage.dart` from this folder (no Bash required). |
| **macOS** | Same as Linux for Flutter; enable USB debugging on a physical device or use an emulator via Android Studio. |
| **Linux** | Prefer the [official Flutter SDK](https://docs.flutter.dev/get-started/install/linux) over some distro packages — they can ship an incompatible Dart SDK (“Wrong full snapshot version”). Add `flutter` to your `PATH`, then `flutter doctor`. |

## Setup

**1. Refresh model assets** (from the repository root, after Python training):

```bash
# Linux / macOS
./scripts/sync_mobile_assets.sh
```

```powershell
# Windows (PowerShell)
.\scripts\sync_mobile_assets.ps1
```

See [`scripts/README.md`](../scripts/README.md) for all platforms and troubleshooting.

**2. Run the app** (from `mobile/`):

```bash
cd mobile
flutter pub get
flutter run
```

## Bundled model

Versioned under `assets/models/`:

- `agroscan_baseline_float.tflite` — classification **+** conv features for Grad-CAM (exported from `models/agroscan_plantwild.keras` by default — PlantWild bridge, best PlantDoc accuracy)
- `gradcam_classifier_weights.bin` / `.json` — classifier weights for on-device attention map
- `labels.json` (38 PlantVillage classes)

A quantized variant can be generated locally with `export_mobile_tflite.py --quantize` (not used by the app today).

After retraining, run `sync_mobile_assets.sh` (exports via `scripts/export_mobile_explain_tflite.py`).

**Grad-CAM documentation:** [../docs/GRADCAM.md](../docs/GRADCAM.md)

If analysis fails on device with `READ_VARIABLE` in logcat, the bundled model is outdated: rerun `sync_mobile_assets.sh`, then **hot restart** (`R`) or reinstall (`flutter run`).

## User flow

```text
Home → Capture / Gallery → Local analysis → Result
                                              ├── Analyzed regions (Grad-CAM, predicted class)
                                              └── Disease sheet (French advice JSON)
History (local SQLite)
```

## Debugging failed analysis

1. **`flutter run` terminal** — look for `I/flutter` lines:
   - `Analysis failed: ...`
   - `TFLite inference failed: ...`
   - `TFLite tensors: in=... out=...`

2. **Android logcat** (USB debugging):
   ```bash
   adb logcat -c
   adb logcat | grep -iE 'flutter|tflite|Analysis failed|TFLite'
   ```
   Filter by app: `adb logcat --pid=$(adb shell pidof -s com.uqac.agroscan)`

3. **Flutter DevTools** — URL printed when running `flutter run` (Logging tab).

In **debug** builds, the analysis screen shows the exact error (`$e`) in the UI.

After a model change: `flutter clean && flutter run` (not hot reload only).

## Useful commands

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

## Layout

```text
mobile/
├── lib/
│   ├── core/          # theme, constants, permissions
│   ├── data/          # TFLite, SQLite, advice JSON
│   ├── domain/        # models and label → French UI mapping
│   ├── features/      # screens (home, capture, analysis, …)
│   ├── router/        # go_router
│   └── shared/        # reusable widgets
└── assets/
    ├── branding/   # agroscan_logo.svg + launcher PNG
    ├── models/
    └── advice/     # diseases_fr.json (user-facing French content)
```

Android icon: `agroscan_launcher_foreground.png` (transparent margins) + background `#FDFCF8`. **`flutter run` does not refresh the launcher icon** — uninstall the app on the device, then:

```bash
# Linux / macOS: python3 ; Windows: .\.venv\Scripts\python.exe
python3 ../scripts/generate_launcher_icon.py
dart run flutter_launcher_icons
```

## Advice sheets (`assets/advice/diseases_fr.json`)

Each **disease** class in the PlantVillage model (38 labels, including 12 `healthy`) has a French sheet: overview, symptoms, and actions. Keys are derived from technical labels (e.g. `Tomato___Late_blight` → `tomato_late_blight`) via `lib/domain/mappers/advice_key.dart`.

**Check coverage** (works on all platforms from `mobile/`):

```bash
dart run tool/validate_advice_coverage.dart
```

Or from the repository root on Linux/macOS/Git Bash: `./scripts/validate_advice_coverage.sh`

**Tests:** `flutter test test/label_mapper_test.dart`

### Content sources and review

- Last content review: **May 2026**
- Wording aligned with common plant pathology; chemical treatments mentioned only generically (“registered product per label”, professional advice).
- Typical references: extension / university sheets (e.g. Cornell Plant Disease Facts, APS, AAFC, MAPAQ).
- Sheets **do not replace** lab diagnosis or pesticide prescriptions.

To add or edit a sheet: update `diseases_fr.json`, then rerun the validation script above.
