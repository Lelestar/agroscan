import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants.dart';
import '../../domain/mappers/label_mapper.dart';
import '../../domain/models/diagnosis_display.dart';
import 'grad_cam.dart';
import 'preprocess.dart';

export '../../domain/models/diagnosis_display.dart' show InferenceResult;

class DiagnosisService {
  DiagnosisService(this._mapper);

  final LabelMapper _mapper;
  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> initialize() async {
    if (_interpreter != null) return;

    final options = InterpreterOptions()..threads = 2;
    _interpreter = await Interpreter.fromAsset(
      AgroConstants.modelAsset,
      options: options,
    );

    final labelsJson = await rootBundle.loadString(AgroConstants.labelsAsset);
    final decoded = jsonDecode(labelsJson) as List<dynamic>;
    _labels = decoded.cast<String>();

    await GradCamComputer.instance();
  }

  Future<InferenceResult> analyze(File imageFile) async {
    await initialize();
    final stopwatch = Stopwatch()..start();
    final result =
        await _runInference(_interpreter!, _labels, imageFile, _mapper);
    stopwatch.stop();
    final display = _withTopLabels(result.display, result.topLabels);
    return InferenceResult(
      display: display,
      topLabels: result.topLabels,
      heatmap: result.heatmap,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

class _RawInference {
  const _RawInference({
    required this.display,
    required this.topLabels,
    required this.heatmap,
  });

  final DiagnosisDisplay display;
  final List<DiagnosisPrediction> topLabels;
  final Float32List heatmap;
}

Future<_RawInference> _runInference(
  Interpreter interpreter,
  List<String> labels,
  File imageFile,
  LabelMapper mapper,
) async {
  final inputTensor = interpreter.getInputTensor(0);
  final outputs = interpreter.getOutputTensors();
  debugPrint(
    'TFLite tensors: in=${inputTensor.shape} ${inputTensor.type}, '
    'outputs=${outputs.map((t) => t.shape).toList()}, labels=${labels.length}',
  );

  final input = buildModelInput(imageFile);
  if (input.length != inputTensor.numElements()) {
    throw StateError(
      'Input size mismatch: buffer=${input.length} tensor=${inputTensor.numElements()}',
    );
  }

  inputTensor.setTo(input);
  interpreter.invoke();

  Tensor? probsTensor;
  Tensor? convTensor;
  for (final tensor in outputs) {
    final shape = tensor.shape;
    if (shape.length == 2 && shape[1] == labels.length) {
      probsTensor = tensor;
    } else if (shape.length == 4 && shape[1] == 7 && shape[2] == 7) {
      convTensor = tensor;
    }
  }
  if (probsTensor == null || convTensor == null) {
    throw StateError(
        'Unexpected TFLite outputs: ${outputs.map((t) => t.shape)}');
  }

  final logits = _readFloats(probsTensor).take(labels.length).toList();
  final convFeatures = _readFloats(convTensor);

  if (logits.length != labels.length) {
    throw StateError(
      'Output size mismatch: logits=${logits.length} labels=${labels.length}',
    );
  }
  final probabilities = logitsToProbabilities(logits);

  var bestIndex = 0;
  var bestScore = probabilities.first;
  for (var i = 1; i < probabilities.length; i++) {
    if (probabilities[i] > bestScore) {
      bestScore = probabilities[i];
      bestIndex = i;
    }
  }

  assert(() {
    final probSum = probabilities.fold<double>(0, (a, b) => a + b);
    debugPrint(
      'TFLite probs: probΣ=${probSum.toStringAsFixed(3)} '
      'top=${labels[bestIndex]} ${(bestScore * 100).toStringAsFixed(1)}% '
      '(${modelOutputsLookLikeProbabilities(logits) ? "softmax in model" : "softmax applied in app"})',
    );
    return true;
  }());

  final gradCam = await GradCamComputer.instance();
  final heatmap7 = gradCam.computeConvHeatmap(convFeatures, bestIndex);
  final heatmap = GradCamComputer.upsample(heatmap7);

  final top3 = List.generate(probabilities.length, (i) => i)
    ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));

  return _RawInference(
    display: mapper.map(labels[bestIndex], bestScore),
    topLabels: top3
        .take(3)
        .map((i) => _predictionFromLabel(mapper, labels[i], probabilities[i]))
        .toList(),
    heatmap: heatmap,
  );
}

Float32List _readFloats(Tensor tensor) {
  final outBytes = tensor.data;
  return Float32List.fromList(
    outBytes.buffer
        .asFloat32List(outBytes.offsetInBytes, outBytes.lengthInBytes ~/ 4)
        .map((e) => e.toDouble())
        .toList(),
  );
}

/// Top-level for [compute] isolate.
Future<InferenceResult> analyzeInBackground(
  String imagePath,
  List<String> labels,
) async {
  Interpreter? interpreter;
  try {
    final options = InterpreterOptions()..threads = 2;
    interpreter = await Interpreter.fromAsset(
      AgroConstants.modelAsset,
      options: options,
    );

    final result = await _runInference(
      interpreter,
      labels,
      File(imagePath),
      LabelMapper(),
    );
    final display = _withTopLabels(result.display, result.topLabels);
    return InferenceResult(
      display: display,
      topLabels: result.topLabels,
      heatmap: result.heatmap,
      durationMs: 0,
    );
  } catch (e, st) {
    debugPrint('TFLite inference failed: $e\n$st');
    rethrow;
  } finally {
    interpreter?.close();
  }
}

DiagnosisDisplay _withTopLabels(
  DiagnosisDisplay display,
  List<DiagnosisPrediction> topLabels,
) =>
    DiagnosisDisplay(
      plantName: display.plantName,
      diseaseName: display.diseaseName,
      headline: display.headline,
      isHealthy: display.isHealthy,
      confidence: display.confidence,
      adviceKey: display.adviceKey,
      rawLabel: display.rawLabel,
      topLabels: topLabels,
    );

DiagnosisPrediction _predictionFromLabel(
  LabelMapper mapper,
  String label,
  double score,
) {
  final mapped = mapper.map(label, score);
  final displayName = mapped.isHealthy
      ? '${mapped.plantName} - feuille saine'
      : '${mapped.plantName} - ${mapped.diseaseName ?? mapped.headline}';
  return DiagnosisPrediction(
    label: label,
    displayName: displayName,
    score: score,
  );
}
