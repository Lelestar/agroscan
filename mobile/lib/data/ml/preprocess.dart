import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../core/constants.dart';

/// Builds NHWC float32 input [1, 224, 224, 3] for the exported TFLite graph.
///
/// The Keras baseline uses `MobileNetV3Small(include_preprocessing=True)`: a
/// **Rescaling** layer is inside the model (`scale = 1/127.5`, `offset = -1`),
/// so pixels must stay in **[0, 255]** — do **not** divide by 255 in the app
/// (that would apply preprocessing twice and hurt confidence).
///
/// Channel order: R, G, B (same as training). Layout: row-major H×W×C.
///
/// Verified with `scripts/verify_mobile_preprocessing.py` (Keras vs TFLite).
Float32List buildModelInput(File imageFile) {
  final bytes = imageFile.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Impossible de lire l\'image.');
  }

  final resized = img.copyResize(
    decoded,
    width: AgroConstants.inputSize,
    height: AgroConstants.inputSize,
    interpolation: img.Interpolation.linear,
  );

  final buffer = Float32List(
    1 * AgroConstants.inputSize * AgroConstants.inputSize * 3,
  );
  var index = 0;
  for (var y = 0; y < AgroConstants.inputSize; y++) {
    for (var x = 0; x < AgroConstants.inputSize; x++) {
      final pixel = resized.getPixel(x, y);
      buffer[index++] = pixel.r.toDouble();
      buffer[index++] = pixel.g.toDouble();
      buffer[index++] = pixel.b.toDouble();
    }
  }

  return buffer;
}

List<double> softmax(List<double> logits) {
  final maxLogit = logits.reduce(math.max);
  final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
  final sum = exps.reduce((a, b) => a + b);
  return exps.map((e) => e / sum).toList();
}

/// Keras classifiers often export a [softmax] head — outputs already sum to ~1.
/// Applying [softmax] again crushes the top score (e.g. 60% → ~6%).
bool modelOutputsLookLikeProbabilities(List<double> values) {
  if (values.isEmpty) return false;
  if (values.any((v) => v < -1e-4 || v > 1.0 + 1e-3)) return false;
  final sum = values.fold<double>(0, (a, b) => a + b);
  return (sum - 1.0).abs() < 0.05;
}

List<double> logitsToProbabilities(List<double> raw) {
  if (modelOutputsLookLikeProbabilities(raw)) return raw;
  return softmax(raw);
}
