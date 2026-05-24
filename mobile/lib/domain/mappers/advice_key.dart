/// Derives stable advice JSON keys from PlantVillage raw labels.
String adviceKeyFromRawLabel(String rawLabel) {
  if (rawLabel.endsWith('___healthy')) return 'generic_healthy';
  final parts = rawLabel.split('___');
  if (parts.length < 2) return 'generic_disease';
  final plant = _normalizeSegment(parts.first);
  final disease = _normalizeSegment(parts.sublist(1).join('___'));
  return '${plant}_$disease';
}

String _normalizeSegment(String value) {
  return value
      .toLowerCase()
      .replaceAll(',', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
