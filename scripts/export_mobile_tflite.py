#!/usr/bin/env python3
"""Export a mobile-compatible TFLite model (no READ_VARIABLE ops).

The previous dynamic-quant export used an older converter path that produced
ops unsupported by tflite_flutter on Android. This script exports from the
Keras checkpoint with optimizations disabled or DEFAULT (verified: no READ_VARIABLE).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import tensorflow as tf

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_KERAS = ROOT / "models" / "jalon5_weak_classes_best.keras"
DEFAULT_LABELS = ROOT / "models" / "labels.json"
MOBILE_DIR = ROOT / "mobile" / "assets" / "models"


def _bad_ops(interpreter: tf.lite.Interpreter) -> set[str]:
    ops = {d["op_name"] for d in interpreter._get_ops_details()}
    return ops & {"READ_VARIABLE", "VAR_HANDLE", "ASSIGN_VARIABLE"}


def export_tflite(keras_path: Path, *, quantize: bool) -> bytes:
    model = tf.keras.models.load_model(str(keras_path), compile=False)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    if quantize:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
    else:
        converter.optimizations = []
    return converter.convert()


def verify(tflite_bytes: bytes) -> None:
    interp = tf.lite.Interpreter(model_content=tflite_bytes)
    interp.allocate_tensors()
    if _bad_ops(interp):
        raise RuntimeError("Exported model still contains resource-variable ops.")
    inp = interp.get_input_details()[0]
    x = np.zeros(inp["shape"], dtype=inp["dtype"])
    interp.set_tensor(inp["index"], x)
    interp.invoke()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--keras", type=Path, default=DEFAULT_KERAS)
    parser.add_argument("--labels", type=Path, default=DEFAULT_LABELS)
    parser.add_argument("--out-dir", type=Path, default=MOBILE_DIR)
    parser.add_argument(
        "--quantize",
        action="store_true",
        help="Use DEFAULT quantization (~1 MB). Default: float32 (~3.7 MB).",
    )
    args = parser.parse_args()

    if not args.keras.exists():
        print(f"Missing Keras model: {args.keras}", file=sys.stderr)
        return 1

    print(f"Loading {args.keras}...")
    tflite = export_tflite(args.keras, quantize=args.quantize)
    print(f"Verifying ({len(tflite) / 1024:.0f} KB)...")
    verify(tflite)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    out_name = (
        "agroscan_baseline_dynamic_quant.tflite"
        if args.quantize
        else "agroscan_baseline_float.tflite"
    )
    out_path = args.out_dir / out_name
    out_path.write_bytes(tflite)
    print(f"Wrote {out_path}")

    if args.labels.exists():
        labels_dest = args.out_dir / "labels.json"
        labels_dest.write_text(args.labels.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"Synced {labels_dest}")

    # Also update models/ for consistency
    models_dir = ROOT / "models"
    models_dir.mkdir(exist_ok=True)
    (models_dir / out_name).write_bytes(tflite)
    print(f"Wrote {models_dir / out_name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
