import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// Grad-CAM-style map (GAP + Dense inference) from conv features and classifier weights.
class GradCamComputer {
  GradCamComputer._(this._weights);

  final Float32List _weights;
  static const _channels = 576;
  static const _spatial = 7;
  static const _classCount = 38;

  static GradCamComputer? _instance;

  static Future<GradCamComputer> instance() async {
    if (_instance != null) return _instance!;
    final bytes = await rootBundle.load(AgroConstants.gradCamWeightsAsset);
    final metaJson = await rootBundle.loadString(
      AgroConstants.gradCamWeightsMetaAsset,
    );
    final meta = jsonDecode(metaJson) as Map<String, dynamic>;
    final channels = meta['channels'] as int;
    final classes = meta['classes'] as int;
    final expected = channels * classes * 4;
    if (bytes.lengthInBytes != expected) {
      throw StateError(
        'Grad-CAM weights size mismatch: ${bytes.lengthInBytes} vs $expected',
      );
    }
    _instance = GradCamComputer._(
      bytes.buffer.asFloat32List(0, channels * classes),
    );
    return _instance!;
  }

  /// Returns a normalized [7×7] map in [0, 1] for [classIndex].
  Float32List computeConvHeatmap(Float32List convFeatures, int classIndex) {
    if (classIndex < 0 || classIndex >= _classCount) {
      throw RangeError('classIndex out of range: $classIndex');
    }
    if (convFeatures.length != _channels * _spatial * _spatial) {
      throw StateError(
        'conv features length ${convFeatures.length}, expected ${_channels * _spatial * _spatial}',
      );
    }
    final heatmap7 = Float32List(_spatial * _spatial);
    var maxVal = 0.0;
    for (var y = 0; y < _spatial; y++) {
      for (var x = 0; x < _spatial; x++) {
        var sum = 0.0;
        final base = (y * _spatial + x) * _channels;
        for (var c = 0; c < _channels; c++) {
          sum += convFeatures[base + c] * _weights[c * _classCount + classIndex];
        }
        final v = sum > 0 ? sum : 0.0;
        heatmap7[y * _spatial + x] = v;
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal > 0) {
      for (var i = 0; i < heatmap7.length; i++) {
        heatmap7[i] /= maxVal;
      }
    }
    return heatmap7;
  }

  /// Upsamples the 7×7 map to [outSize]×[outSize] (bilinear).
  static Float32List upsample(
    Float32List heatmap7, {
    int outSize = AgroConstants.inputSize,
  }) {
    final out = Float32List(outSize * outSize);
    for (var y = 0; y < outSize; y++) {
      for (var x = 0; x < outSize; x++) {
        final sy = (y + 0.5) * _spatial / outSize - 0.5;
        final sx = (x + 0.5) * _spatial / outSize - 0.5;
        out[y * outSize + x] = _sampleBilinear(heatmap7, sx, sy);
      }
    }
    return out;
  }

  static double _sampleBilinear(Float32List map, double x, double y) {
    final x0 = x.floor().clamp(0, _spatial - 1);
    final y0 = y.floor().clamp(0, _spatial - 1);
    final x1 = (x0 + 1).clamp(0, _spatial - 1);
    final y1 = (y0 + 1).clamp(0, _spatial - 1);
    final dx = x - x0;
    final dy = y - y0;
    final v00 = map[y0 * _spatial + x0];
    final v10 = map[y0 * _spatial + x1];
    final v01 = map[y1 * _spatial + x0];
    final v11 = map[y1 * _spatial + x1];
    final v0 = v00 * (1 - dx) + v10 * dx;
    final v1 = v01 * (1 - dx) + v11 * dx;
    return v0 * (1 - dy) + v1 * dy;
  }

  static Future<void> writeHeatmapFile(String path, Float32List heatmap) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(
      heatmap.buffer.asUint8List(
        heatmap.offsetInBytes,
        heatmap.lengthInBytes,
      ),
      flush: true,
    );
  }

  static Future<Float32List?> readHeatmapFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    final expected = AgroConstants.inputSize * AgroConstants.inputSize * 4;
    if (bytes.length != expected) return null;
    return bytes.buffer.asFloat32List(0, bytes.length ~/ 4);
  }
}
