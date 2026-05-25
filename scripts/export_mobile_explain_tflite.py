#!/usr/bin/env python3
"""Export TFLite: probabilities [1,38] + conv features [1,7,7,576] + classifier weights for Grad-CAM on device.

Grad-CAM is computed in Dart (forward pass only — no gradient ops in TFLite).
Same mobile preprocessing: float32 NHWC pixels in [0, 255].
"""
from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import tensorflow as tf

ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "models"
# PlantWild bridge (jalon3) — best PlantDoc accuracy; fallback to baseline.
DEFAULT_KERAS = MODEL_DIR / "agroscan_plantwild.keras"
FALLBACK_KERAS = MODEL_DIR / "agroscan_baseline.keras"
DEFAULT_LABELS = MODEL_DIR / "labels.json"
MOBILE_DIR = ROOT / "mobile" / "assets" / "models"
IMG_SIZE = (224, 224)
CONV_SHAPE = (7, 7, 576)


def _bad_ops(interpreter: tf.lite.Interpreter) -> set[str]:
    ops = {d["op_name"] for d in interpreter._get_ops_details()}
    return ops & {"READ_VARIABLE", "VAR_HANDLE", "ASSIGN_VARIABLE"}


def build_dual_output_model(full_model: tf.keras.Model) -> tf.keras.Model:
    backbone = full_model.layers[1]
    conv_model = tf.keras.Model(
        inputs=backbone.input,
        outputs=backbone.get_layer("conv_1").output,
    )
    feat_model = tf.keras.Model(inputs=backbone.input, outputs=backbone.output)

    image_input = tf.keras.Input(shape=(*IMG_SIZE, 3), dtype=tf.float32, name="image")
    conv_out = conv_model(image_input)
    features = feat_model(image_input)
    x = features
    for layer in full_model.layers[2:]:
        if isinstance(layer, tf.keras.layers.Dropout):
            x = layer(x, training=False)
        else:
            x = layer(x)
    probabilities = x
    return tf.keras.Model(
        inputs=image_input,
        outputs={
            "probabilities": probabilities,
            "conv_features": conv_out,
        },
        name="agroscan_dual",
    )


def _classifier_dense(full_model: tf.keras.Model) -> tf.keras.layers.Dense:
    for layer in reversed(full_model.layers):
        if isinstance(layer, tf.keras.layers.Dense):
            return layer
    raise ValueError("No Dense classifier layer found in Keras model")


def export_classifier_weights(
    full_model: tf.keras.Model,
    dest: Path,
    *,
    keras_path: Path,
    tflite_path: Path,
) -> None:
    dense = _classifier_dense(full_model)
    kernel, _bias = dense.get_weights()
    if kernel.shape != (CONV_SHAPE[2], 38):
        raise ValueError(f"Unexpected dense kernel shape {kernel.shape}")
    dest.write_bytes(kernel.astype(np.float32).tobytes())
    keras_bytes = keras_path.read_bytes()
    meta = {
        "channels": int(CONV_SHAPE[2]),
        "classes": int(kernel.shape[1]),
        "spatial": [int(CONV_SHAPE[0]), int(CONV_SHAPE[1])],
        "format": "float32_column_major_kernel",
        "source_keras": keras_path.name,
        "source_keras_path": str(keras_path.resolve()),
        "source_keras_md5": hashlib.md5(keras_bytes).hexdigest(),
        "tflite_asset": tflite_path.name,
        "exported_at": datetime.now(timezone.utc).isoformat(),
    }
    dest.with_suffix(".json").write_text(json.dumps(meta, indent=2) + "\n")


def export_tflite(keras_path: Path) -> bytes:
    full_model = tf.keras.models.load_model(str(keras_path))
    dual = build_dual_output_model(full_model)
    converter = tf.lite.TFLiteConverter.from_keras_model(dual)
    converter.optimizations = []
    return converter.convert()


def verify(tflite_bytes: bytes) -> None:
    interp = tf.lite.Interpreter(model_content=tflite_bytes)
    interp.allocate_tensors()
    if _bad_ops(interp):
        raise RuntimeError("Exported model contains resource-variable ops.")
    inputs = interp.get_input_details()
    outputs = interp.get_output_details()
    print("Inputs:", [(i["name"], i["shape"], i["dtype"]) for i in inputs])
    print("Outputs:", [(o["name"], o["shape"], o["dtype"]) for o in outputs])
    x = np.random.rand(1, 224, 224, 3).astype(np.float32) * 255.0
    interp.set_tensor(inputs[0]["index"], x)
    interp.invoke()
    for o in outputs:
        out = interp.get_tensor(o["index"])
        print(f"  {o['name']}: shape={out.shape} min={out.min():.4f} max={out.max():.4f}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--keras",
        type=Path,
        default=None,
        help=f"Keras model (default: {DEFAULT_KERAS.name}, else {FALLBACK_KERAS.name})",
    )
    parser.add_argument("--labels", type=Path, default=DEFAULT_LABELS)
    parser.add_argument("--out-dir", type=Path, default=MOBILE_DIR)
    parser.add_argument(
        "--out-name",
        default="agroscan_baseline_float.tflite",
    )
    args = parser.parse_args()

    keras_path = args.keras
    if keras_path is None:
        keras_path = DEFAULT_KERAS if DEFAULT_KERAS.exists() else FALLBACK_KERAS
    if not keras_path.exists():
        print(
            f"Missing Keras model. Expected {DEFAULT_KERAS} or {FALLBACK_KERAS}",
            file=sys.stderr,
        )
        return 1

    full_model = tf.keras.models.load_model(str(keras_path))

    print(f"Building dual-output model from {keras_path}...")
    tflite = export_tflite(keras_path)
    print(f"Verifying TFLite ({len(tflite) / 1024:.0f} KB)...")
    verify(tflite)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    out_path = args.out_dir / args.out_name
    out_path.write_bytes(tflite)
    print(f"Wrote {out_path}")

    weights_path = args.out_dir / "gradcam_classifier_weights.bin"
    export_classifier_weights(
        full_model,
        weights_path,
        keras_path=keras_path.resolve(),
        tflite_path=out_path.resolve(),
    )
    print(f"Wrote {weights_path} (+ .json)")

    labels_dest = args.out_dir / "labels.json"
    if args.labels.exists():
        labels_dest.write_bytes(args.labels.read_bytes())
        print(f"Synced {labels_dest}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
