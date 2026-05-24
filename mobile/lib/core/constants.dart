abstract final class AgroConstants {
  static const logoAsset = 'assets/branding/agroscan_logo.svg';
  static const inputSize = 224;
  static const lowConfidenceThreshold = 0.5;
  static const modelAsset =
      'assets/models/agroscan_baseline_float.tflite';
  static const labelsAsset = 'assets/models/labels.json';
  static const gradCamWeightsAsset =
      'assets/models/gradcam_classifier_weights.bin';
  static const gradCamWeightsMetaAsset =
      'assets/models/gradcam_classifier_weights.json';
  static const adviceAsset = 'assets/advice/diseases_fr.json';
}
