# AgroScan

AgroScan is a student project for the UQAC course **8INF934 - Atelier pratique en intelligence artificielle I**.

The goal is to build a mobile-oriented plant disease diagnosis pipeline. A user takes or imports a photo of a leaf, the model runs locally on the device, and the application returns a preliminary diagnosis with a confidence score, a visual explanation, and simple recommendations.

The project currently focuses on the AI pipeline:

- PlantVillage baseline training with transfer learning.
- Evaluation on a held-out PlantVillage test split.
- Cross-dataset evaluation on PlantDoc for more realistic field images.
- Grad-CAM visual explanation.
- TensorFlow Lite export for future Flutter mobile integration.

## Repository Structure

```text
.
├── notebooks/
│   └── jalon2_pipeline_baseline.ipynb
├── scripts/
│   └── tf_gpu_env.sh             # TensorFlow GPU runtime helper
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

On Linux, TensorFlow may still fail to find the CUDA/cuDNN shared libraries installed inside `.venv`. The helper script sets `LD_LIBRARY_PATH` to include the NVIDIA libraries from the virtual environment.

To check GPU detection:

```bash
./scripts/tf_gpu_env.sh python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

To launch Jupyter with the same GPU configuration:

```bash
./scripts/tf_gpu_env.sh jupyter lab
```

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

## Running the Baseline Notebook

Start Jupyter:

```bash
source .venv/bin/activate
./scripts/tf_gpu_env.sh jupyter lab
```

Then open:

```text
notebooks/jalon2_pipeline_baseline.ipynb
```

The notebook performs:

1. Environment and GPU checks.
2. PlantVillage loading and split creation.
3. MobileNetV3Small transfer-learning baseline.
4. Test evaluation with accuracy, macro F1 and classification report.
5. Confusion matrix and error analysis.
6. Grad-CAM example generation.
7. TensorFlow Lite export.
8. PlantDoc evaluation on common classes.

## Current Baseline Results

Latest PlantVillage baseline run:

- Test accuracy: **94.98%**
- Test macro F1: **93.63%**
- Weighted F1: **94.90%**
- Errors: **409 / 8145 images**
- Local inference timing: **1.02 ms/image** in the current GPU environment
- Dynamic-quantized TFLite export: **0.18 MB**

Latest PlantDoc evaluation on common classes:

- Evaluated images: **236**
- Common classes: **27**
- Accuracy: **22.88%**
- Macro F1: **17.39%**
- Mean prediction confidence: **63.37%**

These results should be interpreted carefully. PlantVillage is a controlled dataset with centered leaves and clean backgrounds, so performance is optimistic compared with real mobile photos. The PlantDoc evaluation confirms a significant domain shift: the current baseline is technically functional, but not robust enough yet for reliable field diagnosis.

## Mobile Direction

The final product is intended to be a Flutter mobile application with local inference. The app should work without requiring a network connection, which is important for use in gardens, orchards or small farms with poor connectivity.

The planned mobile flow is:

```text
Home -> Capture/Import -> Local Analysis -> Diagnosis Result
                               ├── Visual Explanation
                               └── Disease Advice
```

The model output should remain cautious: the app provides a preliminary diagnosis, not a definitive expert decision.

## Authors

- Léon Morales
- Léonard Zipper
