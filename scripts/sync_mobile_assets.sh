#!/usr/bin/env bash
# Copy trained model artifacts into the Flutter app bundle.
# Windows: use scripts/sync_mobile_assets.ps1
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_MODELS="${ROOT}/models"
DEST="${ROOT}/mobile/assets/models"
PYTHON="${ROOT}/.venv/bin/python"

if [[ ! -x "${PYTHON}" ]]; then
  PYTHON=python3
fi

mkdir -p "${DEST}"

if [[ ! -f "${SRC_MODELS}/agroscan_baseline.keras" ]]; then
  echo "Missing ${SRC_MODELS}/agroscan_baseline.keras — train the model first." >&2
  exit 1
fi

echo "Exporting TFLite (predictions + conv features for Grad-CAM)..."
"${PYTHON}" "${ROOT}/scripts/export_mobile_explain_tflite.py"

for file in \
  agroscan_baseline_float.tflite \
  gradcam_classifier_weights.bin \
  gradcam_classifier_weights.json \
  labels.json; do
  if [[ ! -f "${DEST}/${file}" ]]; then
    echo "Missing ${DEST}/${file} after export." >&2
    exit 1
  fi
  echo "Ready ${DEST}/${file}"
done

echo "Mobile assets ready in ${DEST}"
