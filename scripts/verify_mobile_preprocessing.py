#!/usr/bin/env python3
"""Verify mobile TFLite input matches Keras baseline (MobileNetV3 include_preprocessing).

Run from repo root:
  .venv/bin/python scripts/verify_mobile_preprocessing.py

Expected:
  - TFLite input [1, 224, 224, 3] float32
  - MobileNetV3Small contains Rescaling(scale=1/127.5, offset=-1) → feed pixels in [0, 255]
  - float32 pixels 0–255: Keras and TFLite outputs match (L1 ≈ 0)
  - float32 pixels 0–1: different predictions (wrong input scale for this export)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import tensorflow as tf

ROOT = Path(__file__).resolve().parents[1]
_MODEL_DIR = ROOT / "models"
KERAS = (
    _MODEL_DIR / "agroscan_plantwild.keras"
    if (_MODEL_DIR / "agroscan_plantwild.keras").exists()
    else _MODEL_DIR / "agroscan_baseline.keras"
)
TFLITE = ROOT / "mobile" / "assets" / "models" / "agroscan_baseline_float.tflite"
LABELS = ROOT / "mobile" / "assets" / "models" / "labels.json"


def main() -> int:
    if not KERAS.exists() or not TFLITE.exists():
        print(f"Missing {KERAS} or mobile TFLite asset.", file=sys.stderr)
        return 1

    labels = json.loads(LABELS.read_text(encoding="utf-8"))
    model = tf.keras.models.load_model(str(KERAS))
    backbone = model.get_layer("MobileNetV3Small")
    rescale = backbone.get_layer("rescaling")
    cfg = rescale.get_config()
    print("MobileNetV3Small rescaling:", cfg)

    interp = tf.lite.Interpreter(model_content=TFLITE.read_bytes())
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    print("TFLite input:", inp["shape"], inp["dtype"])
    print("TFLite output:", out["shape"], out["dtype"])
    print("Head activation:", model.layers[-1].activation)

    rng = np.random.default_rng(42)
    image = rng.integers(0, 256, size=(224, 224, 3), dtype=np.uint8)

    def run_keras(x: np.ndarray) -> np.ndarray:
        return model.predict(x[None, ...], verbose=0)[0]

    def run_tflite(x: np.ndarray) -> np.ndarray:
        x = x.astype(np.float32)[None, ...]
        interp.set_tensor(inp["index"], x)
        interp.invoke()
        return interp.get_tensor(out["index"])[0]

    x255 = image.astype(np.float32)
    x01 = image.astype(np.float32) / 255.0

    yk255, yt255 = run_keras(x255), run_tflite(x255)
    yk01, yt01 = run_keras(x01), run_tflite(x01)

    def report(name: str, yk: np.ndarray, yt: np.ndarray) -> None:
        l1 = float(np.abs(yk - yt).sum())
        print(f"\n{name}:")
        print(f"  keras  max={yk.max():.4f} ({yk.max()*100:.1f}%) class={labels[int(yk.argmax())]}")
        print(f"  tflite max={yt.max():.4f} ({yt.max()*100:.1f}%) class={labels[int(yt.argmax())]}")
        print(f"  L1 diff={l1:.6f}  argmax_match={yk.argmax() == yt.argmax()}")

    report("float32 [0,255] (mobile buildModelInput)", yk255, yt255)
    report("float32 [0,1]   (WRONG for this model)", yk01, yt01)

    ok = (
        yk255.argmax() == yt255.argmax()
        and np.abs(yk255 - yt255).sum() < 1e-3
        and abs(float(yk255.sum()) - 1.0) < 0.01
    )
    print("\n" + ("OK: mobile preprocessing matches TFLite/Keras." if ok else "FAIL: mismatch."))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
