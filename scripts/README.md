# AgroScan scripts

Helper scripts for training export, mobile assets, and content checks. **Python scripts are cross-platform** (Windows, macOS, Linux). **Shell wrappers** differ by OS.

## Quick reference by OS

| Task | Linux / macOS | Windows (PowerShell) |
|------|---------------|---------------------|
| Refresh mobile TFLite + Grad-CAM assets | `./scripts/sync_mobile_assets.sh` | `.\scripts\sync_mobile_assets.ps1` |
| Validate `diseases_fr.json` coverage | `./scripts/validate_advice_coverage.sh` | `.\scripts\validate_advice_coverage.ps1` |
| Same validation (any OS) | `cd mobile && dart run tool/validate_advice_coverage.dart` | `cd mobile; dart run tool/validate_advice_coverage.dart` |
| Verify image preprocessing | `.venv/bin/python scripts/verify_mobile_preprocessing.py` | `.\.venv\Scripts\python.exe scripts\verify_mobile_preprocessing.py` |
| Regenerate launcher PNGs | `python scripts/generate_launcher_icon.py` | `.\.venv\Scripts\python.exe scripts\generate_launcher_icon.py` |
| Jupyter with GPU (Linux) | `./scripts/tf_gpu_env.sh jupyter lab` | Use [TensorFlow GPU install](https://www.tensorflow.org/install/pip) for Windows |

On **Windows**, you can also use **Git Bash** to run the `.sh` scripts if you prefer.

## Script details

### `sync_mobile_assets.sh` / `sync_mobile_assets.ps1`

**When:** after training or updating `models/agroscan_baseline.keras`, before running the Flutter app.

**Does:** runs `export_mobile_explain_tflite.py` and checks that these files exist under `mobile/assets/models/`:

- `agroscan_baseline_float.tflite`
- `gradcam_classifier_weights.bin` / `.json`
- `labels.json`

**Requires:** Python venv with TensorFlow (see root `README.md`).

---

### `export_mobile_explain_tflite.py`

**When:** manual/debug export (normally called by sync scripts).

**Does:** builds dual-output TFLite (probabilities + `conv_1` features) and Grad-CAM classifier weights for the mobile app.

```bash
# Any OS (from repo root, venv activated)
python scripts/export_mobile_explain_tflite.py
```

---

### `export_mobile_tflite.py` (optional)

**When:** experiments only — **not used by the Flutter app**.

**Does:** classification-only or dynamic-quantized TFLite export.

```bash
python scripts/export_mobile_tflite.py --quantize
```

---

### `validate_advice_coverage.sh` / `validate_advice_coverage.ps1`

**When:** after editing `mobile/assets/advice/diseases_fr.json`.

**Does:** ensures every PlantVillage disease label has a matching advice key.

---

### `verify_mobile_preprocessing.py`

**When:** after changing `mobile/lib/data/ml/preprocess.dart` or the TFLite export.

**Does:** compares Keras vs TFLite outputs for input scale `[0, 255]` vs `[0, 1]`.

---

### `generate_launcher_icon.py`

**When:** rebranding — after editing `mobile/assets/branding/agroscan_logo.svg`.

**Does:** writes launcher PNGs. **Requires [`rsvg-convert`](https://wiki.gnome.org/Projects/LibRsvg)** on your `PATH`:

- **Linux:** `librsvg` package (e.g. `pacman -S librsvg`, `apt install librsvg2-bin`)
- **macOS:** `brew install librsvg`
- **Windows:** install from [GTK/librsvg](https://www.gtk.org/docs/installations/windows/) or use WSL

Then in `mobile/`:

```bash
dart run flutter_launcher_icons
```

---

### `tf_gpu_env.sh` (Linux only)

**When:** TensorFlow does not see the GPU inside `.venv` on Linux.

**Does:** prepends NVIDIA library paths from the venv to `LD_LIBRARY_PATH`, then runs your command.

Not applicable on Windows/macOS — use platform-specific TensorFlow GPU setup instead.

## Flutter app (all platforms)

The mobile app itself is built with Flutter on **Windows, macOS, or Linux** (target: Android). See [`mobile/README.md`](../mobile/README.md).

Typical flow after sync:

```bash
cd mobile
flutter pub get
flutter run
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Missing agroscan_baseline.keras` | Train in notebooks; model should land in `models/` |
| `flutter` not found | Install [Flutter SDK](https://docs.flutter.dev/get-started/install), run `flutter doctor` |
| `.sh` permission denied (Linux/macOS) | `chmod +x scripts/*.sh` |
| PowerShell execution policy | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` (or run `powershell -ExecutionPolicy Bypass -File scripts\sync_mobile_assets.ps1`) |
| `rsvg-convert` not found | Install librsvg (see `generate_launcher_icon.py` above) |
