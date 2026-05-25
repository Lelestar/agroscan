# AgroScan

AgroScan is a student project for the UQAC course **8INF934 - Atelier pratique en intelligence artificielle I**.

The goal is to build a mobile-oriented plant disease diagnosis pipeline. A user takes or imports a photo of a leaf, the model runs locally on the device, and the application returns a preliminary diagnosis with a confidence score, a visual explanation, and simple recommendations.

The project currently focuses on the AI pipeline:

- PlantVillage baseline training with transfer learning (jalon 2).
- **Gradual domain adaptation** PlantVillage → PlantWild → PlantDoc (jalon 3, **model shipped in the app**).
- Alternative experiments: merged PV+Wild dataset, full backbone unfreeze.
- Cross-dataset evaluation on PlantDoc for realistic field images.
- Grad-CAM visual explanation (notebooks + [mobile implementation](docs/GRADCAM.md)).
- TensorFlow Lite export for Flutter mobile integration.

## Repository Structure

```text
.
├── docs/
│   └── GRADCAM.md                # architecture Grad-CAM mobile (export, Dart, UI)
├── mobile/                       # Flutter app (Android, on-device TFLite)
├── notebooks/
│   ├── jalon2_pipeline_baseline.ipynb           # baseline PlantVillage → PlantDoc (historical reference)
│   ├── jalon3_pipeline_plantwild.ipynb            # **production** — PV → PlantWild → PlantDoc bridge
│   ├── jalon3_pipeline_merged_pv_wild.ipynb       # experiment — merged Kaggle PV+Wild dataset
│   └── jalon3_pipeline_full_unfreeze.ipynb        # experiment — full backbone unfreeze on PlantDoc
├── scripts/
│   ├── README.md                       # cross-platform script guide (Windows / macOS / Linux)
│   ├── sync_mobile_assets.sh / .ps1    # export TFLite + Grad-CAM → mobile/assets
│   ├── export_mobile_explain_tflite.py # dual TFLite (probs + conv) + CAM weights
│   ├── export_mobile_tflite.py         # classification / quantized export (optional)
│   ├── validate_advice_coverage.sh / .ps1
│   ├── verify_mobile_preprocessing.py  # image preprocessing verification
│   ├── generate_launcher_icon.py       # PNG launcher Android
│   └── tf_gpu_env.sh                   # TensorFlow GPU helper (Linux only)
├── requirements.txt
└── README.md
```

Large local artifacts are intentionally ignored by Git:

- `data/` datasets and TensorFlow Datasets cache
- `models/` trained Keras, SavedModel and TFLite exports
- `reports/` generated metrics, plots and Grad-CAM images
- `.venv/` local Python environment

## Setup

This project uses Python 3.11.

Linux/macOS:

```bash
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Windows PowerShell:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

If the environment already exists, activate it and install the requirements:

Linux/macOS:

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## GPU Notes

TensorFlow is installed with CUDA runtime packages through:

```text
tensorflow[and-cuda]
```

GPU setup depends on your OS — see the [TensorFlow GPU guide](https://www.tensorflow.org/install/pip#windows-native_1) for Windows, macOS (often CPU-only), and Linux.

**Linux:** if `list_physical_devices('GPU')` is empty even after install, the libraries inside `.venv` may not be on `LD_LIBRARY_PATH`. Use the helper script:

```bash
./scripts/tf_gpu_env.sh python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
./scripts/tf_gpu_env.sh jupyter lab
```

**Windows / macOS:** run Jupyter or Python from the activated `.venv` without `tf_gpu_env.sh` (that script is Linux-specific).

## Data

### PlantVillage

PlantVillage is loaded through TensorFlow Datasets in the notebook. The TFDS cache is stored locally under `data/tfds/` and is not tracked by Git.

### PlantDoc

PlantDoc must be placed locally with the following structure:

```text
data/plantdoc/
├── train/
│   └── <class folders>/
└── test/
    └── <class folders>/
```

The notebook contains an explicit mapping from PlantDoc class names to PlantVillage labels. This avoids evaluating classes with mismatched or ambiguous names.

### PlantWild

PlantWild is used as a **terrain bridge** between PlantVillage (studio) and PlantDoc (field). Place it locally:

```text
data/plantwild/
├── train/
│   └── <class folders>/
└── test/          # optional
    └── <class folders>/
```

Download: [Kaggle — PlantWild](https://www.kaggle.com/datasets/thuanai1/plantwild) (or `kagglehub` in `jalon3_pipeline_plantwild.ipynb`). Classes are mapped to the 38 PlantVillage labels; unmapped classes are skipped.

## Running the Notebooks

Start Jupyter:

```bash
source .venv/bin/activate
./scripts/tf_gpu_env.sh jupyter lab
```

Then open the notebook that matches your goal:

| Notebook | Role |
|----------|------|
| `jalon2_pipeline_baseline.ipynb` | Historical baseline (PV only, then PlantDoc FT) |
| **`jalon3_pipeline_plantwild.ipynb`** | **Best PlantDoc model** — 3 phases: PV → PlantWild → PlantDoc |
| `jalon3_pipeline_merged_pv_wild.ipynb` | Single merged Kaggle dataset (80 classes) + PlantDoc FT |
| `jalon3_pipeline_full_unfreeze.ipynb` | Variant with 100% backbone unfreeze (high forgetting risk) |

**Recommended for training the app model:** `jalon3_pipeline_plantwild.ipynb` → saves `models/agroscan_plantwild.keras`, then `./scripts/sync_mobile_assets.sh`.

### Mobile model in the app

| Item | Value |
|------|--------|
| Keras checkpoint | `models/agroscan_plantwild.keras` |
| Bundled TFLite | `mobile/assets/models/agroscan_baseline_float.tflite` (legacy filename) |
| Fallback if plantwild missing | `models/agroscan_baseline.keras` |

After sync, `gradcam_classifier_weights.json` records `source_keras` (e.g. `agroscan_plantwild.keras`). The sync script prints `Using Keras model: ...` on export.

## Current Results

Metrics below are on the **38-class PlantVillage label space**; PlantDoc test uses **236 images / 27 mapped classes** (same protocol as jalon 2).

### Jalon 2 — baseline (`jalon2_pipeline_baseline.ipynb`)

| Dataset | Accuracy | Macro F1 |
|---------|----------|----------|
| PlantVillage test | **94.98%** | **93.63%** |
| PlantDoc test | **22.88%** | **17.39%** |

### Jalon 3 — PlantWild bridge (`jalon3_pipeline_plantwild.ipynb`) — **shipped in mobile**

| Dataset | Accuracy | Macro F1 | Notes |
|---------|----------|----------|-------|
| PlantVillage test | **42.77%** | **38.97%** | Strong catastrophic forgetting vs baseline (acceptable if target is field photos) |
| PlantDoc test | **53.39%** | **52.13%** | Best project result on field images; mean confidence **59.78%** |

Compared to the older jalon 2 “improved” PV→PlantDoc direct fine-tune (37.29% PlantDoc accuracy), the PlantWild bridge gains about **+16 pp** accuracy on PlantDoc.

PlantVillage numbers are optimistic for studio data; PlantDoc is closer to real mobile use. The app prioritizes **PlantDoc-style generalization** over retaining studio accuracy.

## Scripts

All helper scripts live under [`scripts/`](scripts/). See **[`scripts/README.md`](scripts/README.md)** for a **Windows / macOS / Linux** matrix (which file to run on each OS). You do **not** need to run every script — only those that match your task.

| Script | Needed for the app? | When to run |
|--------|---------------------|-------------|
| [`sync_mobile_assets.sh`](scripts/sync_mobile_assets.sh) / [`.ps1`](scripts/sync_mobile_assets.ps1) | **Yes** | After training: copies dual TFLite + Grad-CAM assets to `mobile/assets/models/`. **Default Keras:** `models/agroscan_plantwild.keras` (jalon3); override with `KERAS_MODEL=...`. |
| [`export_mobile_explain_tflite.py`](scripts/export_mobile_explain_tflite.py) | (called by sync) | Manual use only if you are debugging the mobile export itself (same output as sync). |
| [`export_mobile_tflite.py`](scripts/export_mobile_tflite.py) | **No** (optional) | Legacy / experiments: classification-only or quantized TFLite (~0.18 MB). The Flutter app uses the dual float model from `export_mobile_explain_tflite.py`, not this file. |
| [`validate_advice_coverage.sh`](scripts/validate_advice_coverage.sh) / [`.ps1`](scripts/validate_advice_coverage.ps1) | **Yes** (content) | After editing `mobile/assets/advice/diseases_fr.json`. Or `cd mobile && dart run tool/validate_advice_coverage.dart` on any OS. |
| [`verify_mobile_preprocessing.py`](scripts/verify_mobile_preprocessing.py) | **No** (debug) | After changing `mobile/lib/data/ml/preprocess.dart` or the TFLite export. Checks that Keras and TFLite agree on input scale `[0, 255]`. |
| [`generate_launcher_icon.py`](scripts/generate_launcher_icon.py) | **No** (branding) | Only when updating the app icon from `assets/branding/agroscan_logo.svg`. Then run `dart run flutter_launcher_icons` in `mobile/`. |
| [`tf_gpu_env.sh`](scripts/tf_gpu_env.sh) | **No** (training) | **Linux only** (optional): sets `LD_LIBRARY_PATH` so TensorFlow finds CUDA/cuDNN inside `.venv`. On Windows/macOS, follow TensorFlow GPU docs for your platform instead. |

Typical workflows:

```bash
# Linux / macOS — refresh mobile bundle after training
./scripts/sync_mobile_assets.sh
cd mobile && flutter pub get && flutter run

# Windows PowerShell — same step
.\scripts\sync_mobile_assets.ps1
cd mobile; flutter pub get; flutter run

# Advice JSON (any OS)
cd mobile && dart run tool/validate_advice_coverage.dart

# GPU + Jupyter (Linux only)
./scripts/tf_gpu_env.sh jupyter lab
```

Each Python script also supports `--help` and has a short module docstring at the top.

## Mobile App (Flutter)

An **alpha Android** build lives in [`mobile/`](mobile/). See [`mobile/README.md`](mobile/README.md) for setup, debugging, and Grad-CAM details ([`docs/GRADCAM.md`](docs/GRADCAM.md)).

Quick start (see [mobile/README.md](mobile/README.md) for Windows/macOS details):

```bash
./scripts/sync_mobile_assets.sh   # after training / model export (or export_mobile_explain_tflite.py on Windows)
cd mobile && flutter pub get && flutter run
```

Requires [Flutter](https://docs.flutter.dev/get-started/install) on your `PATH` (`flutter doctor` on all platforms).

Implemented flow:

```text
Home -> Capture/Import -> Local analysis (TFLite) -> Result
                               ├── Analyzed regions (Grad-CAM, predicted class)
                               └── Disease sheet (French advice JSON)
History (local SQLite)
```

Preprocessing matches training: **224×224** images, **float32 pixels in [0, 255]**. MobileNetV3 `Rescaling` is **inside** the TFLite graph — do **not** divide by 255 in the app.

To verify input scale after export: `.venv/bin/python scripts/verify_mobile_preprocessing.py`

The model output remains cautious: preliminary diagnosis only, not a definitive expert decision.

## Authors

- Léon Morales
- Léonard Zipper
