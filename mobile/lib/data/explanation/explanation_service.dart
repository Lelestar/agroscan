import 'dart:typed_data';

import '../local/diagnosis_repository.dart';
import '../ml/grad_cam.dart';

class ExplanationService {
  Future<Float32List?> loadHeatmap(String diagnosisId, String imagePath) async {
    final path = DiagnosisRepository.heatmapPathFor(diagnosisId, imagePath);
    return GradCamComputer.readHeatmapFile(path);
  }
}
